// WriteBmpFile.cpp: implementation of the CWriteBmpFile class.
//
//////////////////////////////////////////////////////////////////////
//#include "x264EncodeDecode.h"
#include "WriteBmpFile.h"


//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CWriteBmpFile::CWriteBmpFile()
{
	m_bmfh.bfType = 0x4D42;
	//m_bmfh.bfSize = sizeof(BITMAPFILEHEADER) + GlobalSize(hDIB);
	m_bmfh.bfReserved1 = 0;
	m_bmfh.bfReserved2 = 0;
	m_bmfh.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);

	m_bmih.biSize=sizeof(BITMAPINFOHEADER);
	//m_bmpinfo.bmiHeader.biWidth=nWidth;
	//m_bmpinfo.bmiHeader.biHeight=nHeight;
	m_bmih.biPlanes=1;
	m_bmih.biBitCount=24;
	m_bmih.biCompression=0;
	m_bmih.biSizeImage=0;
	m_bmih.biXPelsPerMeter=0;
	m_bmih.biYPelsPerMeter=0;
	m_bmih.biClrUsed=0;
	m_bmih.biClrImportant=0;

	m_bOpened = false ;
	m_hFile = NULL;
}

CWriteBmpFile::~CWriteBmpFile()
{
	Close() ;
}

//打开bmp文件。
BOOL CWriteBmpFile::Open(char *szName, int nWidth, int nHeight)
{
	BOOL bRet = false;

	if(szName == NULL || nWidth <= 0 || nHeight <= 0)
		return bRet;

	if(m_bOpened)
		return bRet;

	m_bmih.biWidth = nWidth;
	m_bmih.biHeight = nHeight ;
	m_bmfh.bfSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + nWidth* nHeight * 3 ;

//	m_hFile = CreateFile((LPCWSTR)szName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL) ;
	m_hFile = CreateFile(szName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL) ;
	if(m_hFile != INVALID_HANDLE_VALUE)
	{
		m_bOpened = TRUE ;
		bRet = TRUE ;
	}

	return bRet;
}

void CWriteBmpFile::Close()
{
	if(m_bOpened)
	{
		if(m_hFile != NULL)
		{
			CloseHandle(m_hFile);
			m_hFile = NULL;
		}
		m_bOpened = false ;
	}
}

void CWriteBmpFile::Write(char *szData)
{
	if(szData == NULL)
		return;

	if(m_bOpened)
	{
		DWORD dwWrite ;
		WriteFile(m_hFile,(char*)&m_bmfh,sizeof(m_bmfh),&dwWrite,NULL) ;
		WriteFile(m_hFile,(char*)&m_bmih,sizeof(m_bmih),&dwWrite,NULL) ;
		WriteFile(m_hFile,szData,m_bmih.biWidth * m_bmih.biHeight * 3,&dwWrite,NULL) ;
	}
}
