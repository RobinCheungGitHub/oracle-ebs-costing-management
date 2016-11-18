create or replace PACKAGE BODY XXNBTY_INVREP04_LABOR_OVD_PKG
--------------------------------------------------------------------------------------------
/*
Package Name : XXNBTY_INVREP04_LABOR_OVD_PKG
Author's Name: Jan Michael C. Cuales
Date written: 13-May-2016
RICEFW Object: INVREP04
Description: Package that will generate Labor Overhead and Yield Loss Absorption Report in CSV file
Program Style:
Maintenance History:
Date         Issue#  Name                      Remarks
-----------  ------  -------------------      ------------------------------------------------
13-May-2016          Jan Michael C. Cuales    Initial Development
16-May-2016          Khristine Austero        remove condition "AND    micv.category_set_name LIKE '%SP%'"
06-Jun-2016          Steven S. Santos         Updated package body to remove filter for cost_level = 0,
                                              query used for the FORM column and performance tuning.
07-JUN-2016          Khristine Austero        Update Query to Get FORM value (Add MSIB table and MMT.INVENTORY_ITEM_ID as filtering)
08-JUN-2016          Khristine Austero        remove 0- in the Select GCC to get OVERHEAD_EARNED_GCC
15-JUN-2016          Steven S. Santos         Added TRANSACTION_ID in the subquery to correct number
                                              of records retrieved.
*/
----------------------------------------------------------------------------------------------
IS

   PROCEDURE main_proc ( x_retcode      OUT VARCHAR2
                       , x_errbuf       OUT VARCHAR2
                       , p_entity       VARCHAR2
                       , p_date_from    DATE
                       , p_date_to      DATE
                       , p_org          VARCHAR2
                       , p_item_num     VARCHAR2 )
   IS

      CURSOR c_gen_rep (
             p_entity       VARCHAR2
           , p_date_from    DATE
           , p_date_to      DATE
           , p_org          VARCHAR2
           , p_item_num     VARCHAR2)
      IS
      SELECT
         '="'|| ORG
      ||'","'|| FORM
      ||'","'|| ITEM_NUM
      ||'","'|| ITEM_DESC
      ||'","'|| BATCH_ID
      ||'","'|| TRANSACTION_QUANTITY
      ||'","'|| UOM
      ||'","'|| '$' || TRIM(TO_CHAR(LABOR_EARNED,'999G999G999G990D00000000'))
      ||'","'|| LABOR_EARNED_GCC
      ||'","'|| '$' || TRIM(TO_CHAR(OVERHEAD_EARNED,'999G999G999G990D00000000'))
      ||'","'|| OVERHEAD_EARNED_GCC
      ||'","'|| '$' || TRIM(TO_CHAR(TOTAL_LOH,'999G999G999G990D00000000'))
      ||'","'|| '$' || TRIM(TO_CHAR(YIELD_LOSS,'999G999G999G990D00000000'))
      ||'","'|| YIELD_LOSS_GCC --'$' || TRIM(TO_CHAR(YIELD_LOSS,'999G999G999G990D00000000'))
      ||'","'|| '$' || TRIM(TO_CHAR(TOTAL_EARNED,'999G999G999G9990D00000000'))
      ||'"'   AS LABOR_RECORD
      FROM (SELECT 1 AS INDEX_ID
           ,  OPERATING_UNIT
           ,  ORG
           ,  LEGAL_ENTITY
           ,  ITEM_NUM
           ,  ITEM_DESC
           ,  FORM
           ,  BATCH_ID
           ,  TRANSACTION_QUANTITY
		       ,  TRANSACTION_ID
           ,  UOM 
              /*[START] DEFECT#52*/
           ,  SUM(NVL(LABOR_EARNED,0)) AS LABOR_EARNED
           ,  LABOR_EARNED_GCC
           ,  SUM(NVL(OVERHEAD_EARNED,0)) AS OVERHEAD_EARNED
           ,  OVERHEAD_EARNED_GCC
           ,  SUM(NVL(YIELD_LOSS,0)) AS YIELD_LOSS
           ,  YIELD_LOSS_GCC
           ,  SUM(NVL(LABOR_EARNED,0) + NVL(OVERHEAD_EARNED,0)) AS TOTAL_LOH
           ,  SUM(NVL(LABOR_EARNED,0) + NVL(OVERHEAD_EARNED,0) + NVL(YIELD_LOSS,0)) AS TOTAL_EARNED
              /*[END] DEFECT#52*/
           ,  NULL AS ORG_LABOR_EARNED
           ,  NULL AS ORG_OVERHEAD_EARNED
           ,  NULL AS ORG_YIELD_LOSS
           ,  NULL AS ORG_TOTAL_LOH
           ,  NULL AS ORG_TOTAL_EARNED
           ,  NULL AS GRAND_LABOR_EARNED
           ,  NULL AS GRAND_OVERHEAD_EARNED
           ,  NULL AS GRAND_YIELD_LOSS
           ,  NULL AS GRAND_TOTAL_LOH
           ,  NULL AS GRAND_TOTAL_EARNED
        FROM (
             SELECT /*+ PARALLEL (mmt,4) */ DISTINCT hou.name AS operating_unit
                , ood.organization_code                     AS org
                , xep.name                                  AS legal_entity
                , msib.segment1                             AS item_num
                , msib.description                          AS item_desc
                , (SELECT emi.C_EXT_ATTR2 
                     FROM apps.ego_mtl_sy_items_ext_b emi,
                          apps.ego_attr_groups_v      eag,
                          mtl_system_items_b          msib --/*TIN*/
                    WHERE 1=1
                      AND msib.organization_id = 122
                      AND eag.attr_group_name = 'NBTY_BULK_MFG'
                      AND emi.inventory_item_id = msib.inventory_item_id
                      AND msib.inventory_item_id = mmt.inventory_item_id --/*TIN*/
                      AND emi.attr_group_id = eag.attr_group_id) AS FORM
                , mmt.transaction_reference                 AS batch_id
                , mmt.transaction_quantity                  AS transaction_quantity
                , mmt.transaction_id                        AS transaction_id
                , mmt.transaction_uom                       AS uom 
                , gxel1.trans_amount                        AS LABOR_EARNED
                , (SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7||'.'||gcc.     
                          segment8 
                     FROM xla_distribution_links dl
                        , xla_ae_lines al
                        , xla_ae_headers ah
                        , gl_code_combinations gcc
                    WHERE 1=1
                      AND dl.source_distribution_id_num_1 = gxel1a.line_id
                      --
                    --AND ah.ae_header_id = gxel1.header_id
                      AND ah.event_id = gxel1.event_id
                      AND ah.event_id = gxel1a.event_id
                      --
                      AND dl.source_distribution_type = gxeh.entity_code
                      AND al.ae_header_id = dl.ae_header_id
                      AND ah.application_id =  dl.application_id
                      AND al.ae_line_num = dl.ae_line_num 
                      AND ah.ae_header_id = al.ae_header_id 
                      AND gcc.code_combination_id = al.code_combination_id
                      AND al.accounting_class_code = 'IVA'
                      AND ah.accounting_entry_status_code = 'F' ) LABOR_EARNED_GCC
                , gxel2.trans_amount                        AS OVERHEAD_EARNED
                , (SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7||'.'||gcc.          segment8 
                     FROM xla_distribution_links dl
                        , xla_ae_lines al
                        , xla_ae_headers ah
                        , gl_code_combinations gcc
                    WHERE 1=1
                      AND dl.source_distribution_id_num_1 = gxel2a.line_id
                      --
                    --AND ah.ae_header_id = gxel1.header_id
                      AND ah.event_id = gxel2.event_id
                      --
                      AND dl.source_distribution_type = gxeh.entity_code
                      AND al.ae_header_id = dl.ae_header_id
                      AND ah.application_id =  dl.application_id
                      AND al.ae_line_num = dl.ae_line_num 
                      AND ah.ae_header_id = al.ae_header_id 
                      AND gcc.code_combination_id = al.code_combination_id
                      AND al.accounting_class_code = 'IVA'
                      AND ah.accounting_entry_status_code = 'F' ) OVERHEAD_EARNED_GCC
                , gxel3.trans_amount                        AS YIELD_LOSS
                , (SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7||'.'||gcc.          segment8 
                     FROM xla_distribution_links dl
                        , xla_ae_lines al
                        , xla_ae_headers ah
                        , gl_code_combinations gcc
                    WHERE 1=1
                      AND dl.source_distribution_id_num_1 = gxel3a.line_id
                      --
                    --AND ah.ae_header_id = gxel1.header_id
                      AND ah.event_id = gxel3.event_id
                      --
                      AND dl.source_distribution_type = gxeh.entity_code
                      AND al.ae_header_id = dl.ae_header_id
                      AND ah.application_id =  dl.application_id
                      AND al.ae_line_num = dl.ae_line_num 
                      AND ah.ae_header_id = al.ae_header_id 
                      AND gcc.code_combination_id = al.code_combination_id
                      AND al.accounting_class_code = 'IVA'
                      AND ah.accounting_entry_status_code = 'F' ) YIELD_LOSS_GCC
             FROM mtl_material_transactions    mmt   
                , mtl_system_items_b           msib  
                , mtl_transaction_types        mtt   
                , hr_operating_units           hou           
                , org_organization_definitions ood 
                , xle_entity_profiles          xep          
                , mtl_parameters               mp                
                , gmf_xla_extract_headers      gxeh
                , (SELECT * 
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst           ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                      AND ccm.cost_cmpntcls_code = 'RES_COST'
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA' ) gxel1a
                 , (SELECT * 
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst           ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                      AND ccm.cost_cmpntcls_code = 'RES_OH'
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA' ) gxel2a
                , (SELECT * 
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst           ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                      AND ccm.cost_cmpntcls_code = 'YIELD_RES'
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA' ) gxel3a
                , (SELECT gxel.header_id       AS HEADER_ID
                        , gxel.event_id        AS EVENT_ID
                        , gxel.organization_id AS ORGANIZATION_ID
                        , SUM(gxel.trans_amount) AS TRANS_AMOUNT
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst           ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                      AND ccm.cost_cmpntcls_code = 'RES_COST'
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA'
                    GROUP BY  gxel.header_id
                        , gxel.event_id
                        , gxel.organization_id) gxel1
                , (SELECT gxel.header_id       AS HEADER_ID
                        , gxel.event_id        AS EVENT_ID
                        , gxel.organization_id AS ORGANIZATION_ID
                        , SUM(gxel.trans_amount) AS TRANS_AMOUNT
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst           ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                      AND ccm.cost_cmpntcls_code =  'RES_OH'
                    --AND gxel.COST_LEVEL = 0 
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA'
                    GROUP BY  gxel.header_id
                        , gxel.event_id
                        , gxel.organization_id) gxel2
                , (SELECT gxel.header_id       AS HEADER_ID
                        , gxel.event_id        AS EVENT_ID
                        , gxel.organization_id AS ORGANIZATION_ID
                        , SUM(gxel.trans_amount) AS TRANS_AMOUNT
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst           ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                      AND ccm.cost_cmpntcls_code = 'YIELD_RES'
                    --AND gxel.COST_LEVEL = 0 
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA'
                    GROUP BY gxel.header_id
                        , gxel.event_id
                        , gxel.organization_id) gxel3      
                , (SELECT * 
                     FROM gmf_xla_extract_lines gxel
                        , cm_cmpt_mst ccm
                    WHERE 1=1
                      AND ccm.cost_cmpntcls_id = gxel.cost_cmpntcls_id
                    --AND gxel.COST_LEVEL = 0
                      AND gxel.JOURNAL_LINE_TYPE = 'IVA' ) gxel_master
             WHERE 1=1 
               AND NVL(gxel1.TRANS_AMOUNT,0) != 0
               AND NVL(gxel2.TRANS_AMOUNT,0) != 0
               AND NVL(gxel3.TRANS_AMOUNT, -99999999999) != 0
               AND mmt.inventory_item_id = msib.inventory_item_id
               AND hou.default_legal_context_id = ood.legal_entity
               AND mmt.organization_id = ood.organization_id
               AND mmt.organization_id = msib.organization_id
               AND ood.legal_entity = xep.legal_entity_id
               AND mtt.transaction_type_id = mmt.transaction_type_id
               AND mp.organization_id = mmt.organization_id
               AND mp.process_enabled_flag = 'Y'
               AND gxeh.transaction_id (+) = mmt.transaction_id
               AND gxeh.organization_id (+) = mmt.organization_id
               AND gxeh.inventory_item_id (+)= mmt.inventory_item_id
               AND ((gxeh.valuation_cost_type = 'STD')
                OR gxeh.header_id IS NULL)
               AND mtt.attribute4 IN ('WIP COMP', 'WIP ISSUE')
               AND mmt.transaction_reference IS NOT NULL
               AND gxel_master.header_id = gxeh.header_id
               AND mmt.organization_id = gxel_master.organization_id
               AND gxeh.event_id = gxel_master.event_id
               AND gxel_master.header_id = gxel1.header_id (+)
               AND gxel_master.organization_id = gxel1.organization_id (+)
               AND gxel_master.event_id = gxel1.event_id (+)
               AND gxel_master.header_id = gxel2.header_id (+)
               AND gxel_master.organization_id = gxel2.organization_id (+)
               AND gxel_master.event_id = gxel2.event_id (+)
               AND gxel_master.header_id = gxel3.header_id (+)
               AND gxel_master.organization_id = gxel3.organization_id (+)
               AND gxel_master.event_id = gxel3.event_id (+)
               ---
               AND gxel_master.header_id = gxel1a.header_id (+)
               AND gxel_master.organization_id = gxel1a.organization_id (+)
               AND gxel_master.event_id = gxel1a.event_id (+)
               AND gxel_master.header_id = gxel2a.header_id (+)
               AND gxel_master.organization_id = gxel2a.organization_id (+)
               AND gxel_master.event_id = gxel2a.event_id (+)
               AND gxel_master.header_id = gxel3a.header_id (+)
               AND gxel_master.organization_id = gxel3a.organization_id (+)
               AND gxel_master.event_id = gxel3a.event_id (+)
               --
               /*  
               AND gxel_master.cost_level = gxel1.cost_level (+)
               AND gxel_master.cost_level = gxel2.cost_level (+)
               AND gxel_master.cost_level = gxel3.cost_level (+) 
               */
                   -- PARAMETERS ---
               AND ((mmt.TRANSACTION_DATE >= TO_DATE(P_DATE_FROM,'DD-MON-YY')) 
                OR P_DATE_FROM IS NULL)
               AND ((mmt.TRANSACTION_DATE < (TO_DATE(P_DATE_TO,'DD-MON-YY') + 1))
                OR P_DATE_TO IS NULL)
               AND (ood.ORGANIZATION_CODE = P_ORG
                OR P_ORG IS NULL)
               AND (msib.SEGMENT1 = P_ITEM_NUM
                OR P_ITEM_NUM IS NULL)
               AND (xep.NAME = P_ENTITY
                 OR P_ENTITY IS NULL)
           UNION ALL
            SELECT /*+ parallel(mmt,4) */ DISTINCT hou.NAME AS OPERATING_UNIT
                 , ood.ORGANIZATION_CODE                    AS ORG
                 , xep.NAME                                 AS LEGAL_ENTITY
                 , msib.SEGMENT1                            AS ITEM_NUM
                 , msib.description                         AS ITEM_DESC
                 , (SELECT emi.C_EXT_ATTR2 
                      FROM apps.ego_mtl_sy_items_ext_b emi,
                           mtl_system_items_b          msib, --/*TIN*/
                           apps.ego_attr_groups_v      eag
                     WHERE 1=1
                       AND msib.organization_id = 122
                       AND eag.attr_group_name = 'NBTY_BULK_MFG'
                       AND emi.inventory_item_id = msib.inventory_item_id
                       AND msib.inventory_item_id = mmt.inventory_item_id --/*TIN*/
                       AND emi.attr_group_id = eag.attr_group_id) AS FORM
                 , mmt.TRANSACTION_REFERENCE                AS BATCH_ID
                 , mmt.TRANSACTION_QUANTITY                 AS TRANSACTION_QUANTITY
                 , mmt.transaction_id                       AS TRANSACTION_ID
                 , mmt.TRANSACTION_UOM                      AS UOM
                 , (0-mta1a.BASE_TRANSACTION_VALUE)         AS LABOR_EARNED
                 , (SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7||'.'||gcc.
                           segment8
                      FROM xla_distribution_links  b 
                         , xla_ae_lines            l                 
                         , gl_code_combinations    gcc
                         , xla_ae_headers          xah
                     WHERE 1=1
                       AND b.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
                       AND b.application_id = l.application_id
                       AND b.source_distribution_id_num_1 = mta1.inv_sub_ledger_id
                       AND xah.ae_header_id = l.ae_header_id 
                       AND gcc.code_combination_id = l.code_combination_id
                       AND l.ae_header_id = b.ae_header_id
                       AND l.ae_line_num = b.ae_line_num
                       AND xah.accounting_entry_status_code = 'F'
                       AND l.accounting_class_code = 'OFFSET') AS LABOR_EARNED_GCC
                 , (0-mta2a.BASE_TRANSACTION_VALUE)         AS OVERHEAD_EARNED
                 , (SELECT gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7||'.'||gcc.
                           segment8 
                      FROM xla_distribution_links    b 
                         , xla_ae_lines              l                 
                         , gl_code_combinations      gcc
                         , xla_ae_headers            xah
                     WHERE 1=1
                       AND b.source_distribution_type = 'MTL_TRANSACTION_ACCOUNTS'
                       AND b.application_id = l.application_id
                       AND b.source_distribution_id_num_1 = mta2a.inv_sub_ledger_id
                       AND xah.ae_header_id = l.ae_header_id 
                       AND gcc.code_combination_id = l.code_combination_id
                       AND l.ae_header_id = b.ae_header_id
                       AND l.ae_line_num = b.ae_line_num
                       AND xah.accounting_entry_status_code = 'F'
                       AND l.accounting_class_code = 'OFFSET') AS OVERHEAD_EARNED_GCC
                 , 0 AS YIELD_LOSS
                 , NULL AS YIELD_LOSS_GCC
             FROM  MTL_MATERIAL_TRANSACTIONS  mmt  
                 , MTL_SYSTEM_ITEMS_B         msib 
                 , (SELECT * 
                      FROM MTL_TRANSACTION_ACCOUNTS mta
                     WHERE 1=1
                       AND (mta.accounting_line_type NOT IN ('2') 
                        OR mta.TRANSACTION_ID IS NULL) 
                       AND mta.cost_element_id IN (3,5) )  mta_master
                 , (SELECT * 
                      FROM MTL_TRANSACTION_ACCOUNTS mta
                     WHERE 1=1
                       AND (mta.accounting_line_type NOT IN ('2') 
                        OR mta.TRANSACTION_ID IS NULL) 
                       AND mta.cost_element_id = 3)   mta1a
                 , (SELECT * 
                      FROM MTL_TRANSACTION_ACCOUNTS mta
                     WHERE (mta.accounting_line_type NOT IN ('2') 
                        OR mta.TRANSACTION_ID IS NULL) 
                       AND mta.cost_element_id = 5)   mta2a
                 ---
                 , (SELECT mta.transaction_id    AS TRANSACTION_ID
                         , mta.inventory_item_id AS INVENTORY_ITEM_ID
                         , mta.organization_id   AS ORGANIZATION_ID
                         , mta.inv_sub_ledger_id AS INV_SUB_LEDGER_ID
                         , SUM(mta.BASE_TRANSACTION_VALUE) AS BASE_TRANSACTION_VALUE
                      FROM MTL_TRANSACTION_ACCOUNTS mta
                     WHERE 1=1
                       AND (mta.accounting_line_type NOT IN ('2') 
                        OR mta.TRANSACTION_ID IS NULL) 
                       AND mta.cost_element_id = 3
                     GROUP BY mta.transaction_id   
                         , mta.inventory_item_id
                         , mta.organization_id
                         , mta.inv_sub_ledger_id)   mta1
                 , (SELECT mta.transaction_id    AS TRANSACTION_ID
                         , mta.inventory_item_id AS INVENTORY_ITEM_ID
                         , mta.organization_id   AS ORGANIZATION_ID
                         , mta.inv_sub_ledger_id AS INV_SUB_LEDGER_ID
                         , SUM(mta.BASE_TRANSACTION_VALUE) AS BASE_TRANSACTION_VALUE
                      FROM MTL_TRANSACTION_ACCOUNTS mta
                     WHERE 1=1
                       AND (mta.accounting_line_type NOT IN ('2') 
                        OR mta.TRANSACTION_ID IS NULL) 
                       AND mta.cost_element_id = 5
                     GROUP BY mta.transaction_id   
                        , mta.inventory_item_id
                        , mta.organization_id
                        , mta.inv_sub_ledger_id)   mta2
                 , MTL_TRANSACTION_TYPES        mtt
                 , HR_OPERATING_UNITS           hou           
                 , ORG_ORGANIZATION_DEFINITIONS ood 
                 , XLE_ENTITY_PROFILES          xep          
                 , MTL_PARAMETERS               mp
                 , BOM_RESOURCES                br
                 , CST_ITEM_COST_DETAILS_V      cicdv
             WHERE 1=1
               AND NVL(mta1.BASE_TRANSACTION_VALUE,0) != 0
               AND NVL(mta2.BASE_TRANSACTION_VALUE, -99999999999) != 0
               AND mmt.TRANSACTION_ID = mta_master.TRANSACTION_ID       
               AND mmt.INVENTORY_ITEM_ID = mta_master.INVENTORY_ITEM_ID 
               AND mmt.ORGANIZATION_ID = mta_master.ORGANIZATION_ID     
               AND mta_master.TRANSACTION_ID = mta1.TRANSACTION_ID      (+)
               AND mta_master.INVENTORY_ITEM_ID = mta1.INVENTORY_ITEM_ID(+)
               AND mta_master.ORGANIZATION_ID = mta1.ORGANIZATION_ID    (+)
               AND mta_master.TRANSACTION_ID = mta2.TRANSACTION_ID      (+)
               AND mta_master.INVENTORY_ITEM_ID = mta2.INVENTORY_ITEM_ID(+)
               AND mta_master.ORGANIZATION_ID = mta2.ORGANIZATION_ID    (+)
               AND mmt.INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID    
               AND hou.DEFAULT_LEGAL_CONTEXT_ID = ood.LEGAL_ENTITY   
               AND mmt.ORGANIZATION_ID = ood.ORGANIZATION_ID         
               AND mmt.ORGANIZATION_ID = msib.ORGANIZATION_ID        
               AND ood.LEGAL_ENTITY = xep.LEGAL_ENTITY_ID            
               AND mtt.TRANSACTION_TYPE_ID = mmt.TRANSACTION_TYPE_ID 
               AND mp.ORGANIZATION_ID = mmt.ORGANIZATION_ID          
               AND mp.PROCESS_ENABLED_FLAG = 'N'
               AND mtt.attribute4 IN ('WIP COMP', 'WIP ISSUE')
               AND mmt.TRANSACTION_REFERENCE IS NOT NULL              
               AND cicdv.RESOURCE_ID = br.RESOURCE_ID
               AND cicdv.INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID  
               AND cicdv.ORGANIZATION_ID = mp.ORGANIZATION_ID
               AND cicdv.INVENTORY_ITEM_ID = mmt.INVENTORY_ITEM_ID   
               AND cicdv.ORGANIZATION_ID = mmt.ORGANIZATION_ID       
             --AND cicdv.LEVEL_TYPE =1
               --
               AND mta_master.TRANSACTION_ID = mta1a.TRANSACTION_ID      (+)
               AND mta_master.INVENTORY_ITEM_ID = mta1a.INVENTORY_ITEM_ID(+)
               AND mta_master.ORGANIZATION_ID = mta1a.ORGANIZATION_ID    (+)
               AND mta_master.TRANSACTION_ID = mta2a.TRANSACTION_ID      (+)
               AND mta_master.INVENTORY_ITEM_ID = mta2a.INVENTORY_ITEM_ID(+)
               AND mta_master.ORGANIZATION_ID = mta2a.ORGANIZATION_ID    (+)
               --
                 -- PARAMETERS ---
               AND ((mmt.TRANSACTION_DATE >= TO_DATE(P_DATE_FROM,'DD-MON-YY')) 
                OR P_DATE_FROM IS NULL)
               AND ((mmt.TRANSACTION_DATE < (TO_DATE(P_DATE_TO,'DD-MON-YY') + 1))
                OR P_DATE_TO IS NULL)
               AND (ood.ORGANIZATION_CODE = P_ORG
                OR P_ORG IS NULL)
               AND (msib.SEGMENT1 = P_ITEM_NUM
                OR P_ITEM_NUM IS NULL)
               AND (xep.NAME = P_ENTITY
                OR P_ENTITY IS NULL)
        )
         GROUP BY 1
             , OPERATING_UNIT
             , ORG
             , LEGAL_ENTITY
             , ITEM_NUM
             , ITEM_DESC
             , FORM
             , BATCH_ID
             , TRANSACTION_QUANTITY
             , TRANSACTION_ID
             , UOM 
             , LABOR_EARNED_GCC
             , OVERHEAD_EARNED_GCC
             , YIELD_LOSS_GCC
             , null
      )
	  ORDER BY ORG
             , FORM
             , ITEM_NUM
             , BATCH_ID;

      TYPE rep_tab_type IS TABLE OF c_gen_rep%ROWTYPE;

      l_rep_tab       rep_tab_type;
      l_header        VARCHAR2(32000);

      v_step          NUMBER;
      v_mess          VARCHAR2(1000);

   BEGIN
      v_step := 1;
      --Print Report Header

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , , ,  NBTY Labor Overhead and Yield Loss Absorption Report');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , INPUT PARAMETERS');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , Legal Entity: ' ||' , '|| p_entity ||' , , , , , , Report Creation Date : ' ||' , '|| TO_CHAR(SYSDATE, 'DD-MON-YY'));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , Date From: ' ||' , '|| p_date_from || ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , Date To: ' ||' , '|| p_date_to || ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , Organization: ' ||' ,="'|| p_org || '"');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' , , , , Item Number: ' ||' , '|| p_item_num || ' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

      l_header := 'Org,Form,Item Number,Item Description,Batch / Word Order ID,Units Manufactured,Primary UOM,Labor Earned,Labor Absorption Account,Overhead Earned,Labor OH Absorption Account,Total LOH Earned,Yield Loss Absorption,Yield Loss Absorption Account,Total Earned';

      v_step := 2;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_header);

      OPEN c_gen_rep( p_entity
                    , p_date_from
                    , p_date_to
                    , p_org
                    , p_item_num);

      FETCH c_gen_rep BULK COLLECT INTO l_rep_tab;

      FOR i in 1..l_rep_tab.COUNT

         LOOP

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_rep_tab(i).LABOR_RECORD );

         END LOOP;

      CLOSE c_gen_rep;

      v_step := 3;

   EXCEPTION
      WHEN OTHERS THEN
         v_mess := 'At step ['||v_step||'] - SQLCODE [' ||SQLCODE|| '] - ' ||substr(SQLERRM,1,100);
         x_errbuf  := v_mess;
         x_retcode := 2;

   END main_proc;

END XXNBTY_INVREP04_LABOR_OVD_PKG;

/

show errors;

