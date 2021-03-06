----------------------------------------------------------------------------------------------------
/*
Table Name: XXNBTY_INV_TXN_ARCH
Author's Name: Albert John Flores
Date written: 18-Feb-2016
RICEFW Object: INT01
Description: Archive table for Inventory Transactions Interface
Program Style: 

Maintenance History: 

Date            Issue#      Name                    Remarks 
-----------     ------      -----------             ------------------------------------------------
18-Feb-2016                 Albert Flores           Initial Development

*/
----------------------------------------------------------------------------------------------------

CREATE TABLE xxnbty.xxnbty_inv_txn_arch
(
        source_code                             VARCHAR2(30)
        ,source_line_id                         NUMBER
        ,source_header_id                       NUMBER
        ,process_flag                           NUMBER          
        ,transaction_mode                       NUMBER          
        ,item_segment1                          VARCHAR2(40) 
        ,organization_id                        NUMBER
        ,transaction_quantity                   NUMBER          
        ,transaction_uom                        VARCHAR2(3)     
        ,transaction_date                       DATE            
        ,subinventory_code                      VARCHAR2(10) 
        ,dsp_segment1                           VARCHAR2(40) 
        ,dsp_segment2                           VARCHAR2(40) 
        ,dsp_segment3                           VARCHAR2(40) 
        ,dsp_segment4                           VARCHAR2(40) 
        ,dsp_segment5                           VARCHAR2(40) 
        ,dsp_segment6                           VARCHAR2(40) 
        ,dsp_segment7                           VARCHAR2(40) 
        ,dsp_segment8                           VARCHAR2(40) 
        ,dst_segment1                           VARCHAR2(40) 
        ,dst_segment2                           VARCHAR2(40) 
        ,dst_segment3                           VARCHAR2(40) 
        ,dst_segment4                           VARCHAR2(40) 
        ,dst_segment5                           VARCHAR2(40) 
        ,dst_segment6                           VARCHAR2(40) 
        ,dst_segment7                           VARCHAR2(40) 
        ,dst_segment8                           VARCHAR2(40) 
        ,transaction_type_id                    NUMBER
        ,transaction_reference                  VARCHAR2(240) 
        ,vendor_lot_number                      VARCHAR2(30) 
        ,transfer_subinventory                  VARCHAR2(10) 
        ,transfer_organization                  NUMBER 
        ,shipment_number                        VARCHAR2(30) 
        ,lot_number                             VARCHAR2(150)
        ,batch_complete                         VARCHAR2(150)
        ,batch_size                             VARCHAR2(150) 
        ,batch_completion_date                  VARCHAR2(150)
        ,reason_code                            VARCHAR2(10)    
        ,transaction_code                       VARCHAR2(10)    
        ,status_code                            VARCHAR2(10) 
        ,as400_source_warehouse                 VARCHAR2(30)            
        ,as400_dest_warehouse                   VARCHAR2(30)
        ,status_flag                            VARCHAR2(10)    
        ,error_description                      VARCHAR2 (1000)
        ,last_update_date                       DATE
        ,last_updated_by                        NUMBER
        ,creation_date                          DATE
        ,created_by                             NUMBER
        ,last_update_login                      NUMBER
)

/

show errors;
