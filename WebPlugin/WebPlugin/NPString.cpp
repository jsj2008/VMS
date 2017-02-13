//kk: helper to wrap some common string tasks
#ifdef _WIN32
#include "stdafx.h"
#endif

#include "NPString.h"
#ifdef __APPLE__
/*-----------------------------------
 完成 memcpy 和 串结束'\0'的功能
 ENTRY:同 memcpy
 RETURN: void
 -------------------------------------*/
void StrCpyN( char*dst, const char*src, int len)
{
    memcpy( dst, src, len);
    dst[len] = 0;
}
#endif
CNPString::CNPString(NPString npString) : m_pszData(0), m_len(0)
{
	Set( npString.UTF8Characters, npString.UTF8Length );
}

CNPString::CNPString(LPCTSTR psz, int len) : m_pszData(0), m_len(0)
{
	Set( psz, len );
}

CNPString::~CNPString()
{
	delete m_pszData;
}

void CNPString::Set(LPCTSTR psz, int len)
{
	delete m_pszData;
	m_len = len + 1;
	m_pszData = new TCHAR[m_len];
	StrCpyN( m_pszData, psz, m_len );
}

CNPString::operator LPCTSTR()
{
	return m_pszData;
}

int CNPString::Compare(LPCTSTR psz)
{
	if( m_pszData )
	{
		return strcmp( m_pszData, psz );
	}

	return -1;
}