create table XXNBTY.XXNBTY_MTL_TRX_IFACE_STAGE
(
TRANSACTION_UOM	VARCHAR2(3),
TRANSACTION_DATE	DATE,	
SOURCE_CODE	VARCHAR2(30),	
SOURCE_LINE_ID	NUMBER,	
SOURCE_HEADER_ID	NUMBER,	
PROCESS_FLAG	NUMBER,	
TRANSACTION_MODE	NUMBER,	
LOCK_FLAG	NUMBER,	
LAST_UPDATE_DATE	DATE,	
LAST_UPDATED_BY	NUMBER,	
CREATION_DATE	DATE,	
CREATED_BY	NUMBER	,	
ITEM_SEGMENT1	VARCHAR2(40),	
SUBINVENTORY_CODE	VARCHAR2(10),	
ORGANIZATION_ID	NUMBER	,	
TRANSACTION_QUANTITY	NUMBER,	
PRIMARY_QUANTITY	NUMBER,	
TRANSACTION_TYPE_ID	NUMBER,	
DST_SEGMENT1	VARCHAR2(25),	
DST_SEGMENT2	VARCHAR2(25),	
DST_SEGMENT3	VARCHAR2(25),	
DST_SEGMENT4	VARCHAR2(25),	
DST_SEGMENT5	VARCHAR2(25),	
DST_SEGMENT6	VARCHAR2(25),	
DST_SEGMENT7	VARCHAR2(25),	
DST_SEGMENT8	VARCHAR2(25),	
TRANSACTION_INTERFACE_ID	NUMBER,
ATTRIBUTE1 VARCHAR2(200)
);


CREATE OR REPLACE SYNONYM APPS.XXNBTY_MTL_TRX_IFACE_STAGE FOR XXNBTY.XXNBTY_MTL_TRX_IFACE_STAGE;