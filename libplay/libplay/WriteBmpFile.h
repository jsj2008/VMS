#ifndef __WRITE_BMP_FILE_H__
#define __WRITE_BMP_FILE_H__


#ifdef WIN32
#include <Windows.h>
#endif

class CWriteBmpFile  
{
public:
 	CWriteBmpFile();
	virtual ~CWriteBmpFile();

	BOOL	Open(char* szName,int nWidth ,int nHeight);
	void	Close();
	void	Write(char* szData);
private:
	BOOL	m_bOpened;
	HANDLE  m_hFile;

    BITMAPFILEHEADER	m_bmfh;
	BITMAPINFOHEADER	m_bmih;
};

#endif
