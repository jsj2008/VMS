#pragma once

//Mozilla-API
#ifdef _WIN32
#include <npfunctions.h>
#include <npruntime.h>
#endif

#ifdef __APPLE__
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>

#define LPCTSTR const char*
#define TCHAR   char 
#endif


class CNPString
{
public:
	CNPString(LPCTSTR psz, int len);
	CNPString(NPString npString);
	~CNPString();

	void Set(LPCTSTR psz, int len);
	operator LPCTSTR ();
	int Compare(LPCTSTR psz);

protected:
	TCHAR *m_pszData;
	int m_len;
};

