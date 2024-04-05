// Code is a Microsoft sample found at http://msdn2.microsoft.com/en-us/library/aa376389.aspx

#include "windows.h"
#include "stdafx.h"


int _tmain(int argc, _TCHAR* argv[])
{
/*++ 
Routine Description: This routine returns TRUE if the caller's
process is a member of the Administrators local group. Caller is NOT
expected to be impersonating anyone and is expected to be able to
open its own process and process token. 
Arguments: None. 
Return Value: 
   TRUE - Caller has Administrators local group. 
   FALSE - Caller does not have Administrators local group. --
*/ 
	BOOL b;
	SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;
	PSID AdministratorsGroup; 
	b = AllocateAndInitializeSid(
		&NtAuthority,
	    2,
		SECURITY_BUILTIN_DOMAIN_RID,
	    DOMAIN_ALIAS_RID_ADMINS,
		0, 0, 0, 0, 0, 0,
	    &AdministratorsGroup); 
	if(b) 
	{
		if (!CheckTokenMembership( NULL, AdministratorsGroup, &b)) 
	    {
		     b = FALSE;
	    } 
		FreeSid(AdministratorsGroup); 
	}
	return(b);
}
