----------------------------------------------------------------------------------------------------
/*
Table Name: GRANT for cst_item_cost_details_v
Author's Name: Khristine Austero
Date written: 23-Feb-2016
RICEFW Object: RCV-INT
Description: Define the grants for SELECT on storage table.
Program Style: 

Maintenance History: 

Date			Issue#		Name					Remarks	
-----------		------		-----------				------------------------------------------------
23-Feb-2016					Khristine Austero		Initial Development

*/
----------------------------------------------------------------------------------------------------

--[PUBLIC GRANT cst_item_cost_details_v]
	GRANT SELECT ON cst_item_cost_details_v TO bolinf;
/

show errors;
