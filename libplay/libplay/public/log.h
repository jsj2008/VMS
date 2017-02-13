#pragma once

#ifndef _LOG_FILE
#define _LOG_FILE TRUE
#endif

// #define _CONSOLE

#include <windows.h>
#include <stdio.h> 
#include <stdarg.h>

struct CLog
{   
    // ȡ����ִ���ļ�����
    static void GetProcessFileName(char* lpName)
    {
        if ( ::GetModuleFileNameA(NULL, lpName, MAX_PATH) > 0) // Ӧ�ó�����
		//if ( ::GetModuleFileNameA(AfxGetInstanceHandle(), lpName, MAX_PATH) > 0) // ģ����
        {
            char* pBegin = lpName;
            char* pTemp  = lpName;
            while ( *pTemp != 0 )
            {
                if ( *pTemp == '\\' )
                {
                    pBegin = pTemp + 1;
                }
                pTemp++;
            }

            memcpy(lpName, pBegin, strlen(pBegin)+1);
        }

    } 
	// ������ļ�
    // lpFile   : Դ�ļ���
    // nLine    : Դ�ļ��к�
    // lpFormat : ���������
    static void Out(LPCSTR lpFile, int nLine, LPCSTR lpFormat, ...)
    {
        if ( NULL == lpFormat )
            return;

        //��ǰʱ��
        SYSTEMTIME st;
        ::GetLocalTime(&st);

        //�õ���Ϣ
        const DWORD BufSize = 2048;
        char szMsg[BufSize];
        /*sprintf_s(szMsg, BufSize, "[%2d:%2d:%2d.%3d]�ļ�%s��%d�У�", 
                                  st.wHour, st.wMinute, st.wSecond, 
                                  st.wMilliseconds, lpFile, nLine);*/

        //sprintf_s(szMsg, BufSize, "[%2d:%2d:%2d.%3d]��", 
        //                          st.wHour, st.wMinute, st.wSecond, 
        //                          st.wMilliseconds);
        sprintf(szMsg,  "[%2d:%2d:%2d.%3d]��", 
                                  st.wHour, st.wMinute, st.wSecond, 
                                  st.wMilliseconds);
        
        char* pTemp = szMsg;
        pTemp += strlen(szMsg);

        va_list args; //��ʽ����Ϣ

        va_start(args, lpFormat);    
//        vsprintf_s(pTemp, BufSize - strlen(szMsg), lpFormat, args);	
		vsprintf(pTemp, lpFormat, args);	
        va_end(args);  

        DWORD dwMsgLen = (DWORD)strlen(szMsg);

        //�õ��ļ���
		char szExeName[MAX_PATH] = {0};
        // ::GetModuleFileNameA(NULL, szExeName, MAX_PATH);
		GetProcessFileName(szExeName);
         
        char szFileName[MAX_PATH];
		/*sprintf_s(szFileName, MAX_PATH, "Log(%d)_%d-%d-%d.txt",
                                        ::GetCurrentProcessId(), 
                                        st.wYear, st.wMonth, st.wDay);*/
        //sprintf_s(szFileName, MAX_PATH, "Log(%s)_%d-%d-%d.txt",
		//                                szExeName, st.wYear, st.wMonth, st.wDay);
		sprintf(szFileName, "Log(%s)_%d-%d-%d.txt",
                                szExeName, st.wYear, st.wMonth, st.wDay);

        // �ļ������Ƿ���ͬ��
        // �����ͬ�رյ�ǰ�ļ���
        // �������ļ�
        static char   s_szFileName[MAX_PATH] = {0};
        static HANDLE s_hFile = INVALID_HANDLE_VALUE; 

        BOOL bNew = (strcmp(s_szFileName, szFileName) != 0) ||
                    (s_hFile == INVALID_HANDLE_VALUE);
        

		static CBaseCS s_cs;
		CAutoLock Lock(&s_cs); // �����ٽ���

// #ifdef _CONSOLE // ����̨���
        //printf("%s", szMsg);
// #endif

        if ( bNew ) // �رվ��ļ����������ļ�
        {
            if ( s_hFile != INVALID_HANDLE_VALUE)
            {
                ::CloseHandle(s_hFile);
                s_hFile = INVALID_HANDLE_VALUE;
            }

            s_hFile = ::CreateFileA( szFileName, 
                                     GENERIC_WRITE, 
                                     FILE_SHARE_WRITE | FILE_SHARE_READ, 
                                     0, 
                                     OPEN_ALWAYS, 
                                     FILE_ATTRIBUTE_NORMAL, 
                                     0);

            if ( s_hFile == INVALID_HANDLE_VALUE)
            {
                printf("::CreateFile Error: %d", ::GetLastError());
                return;
            }
        }

        //д���ļ�
        if ( s_hFile != INVALID_HANDLE_VALUE) 
        {
            DWORD dwWrite = 0;
            ::SetFilePointer(s_hFile, 0, NULL, FILE_END);
            ::WriteFile(s_hFile, szMsg, dwMsgLen, &dwWrite, NULL);            
        }
    }
}; // CLog

#if (_LOG_FILE)    
    //#define OUTLOG(...) CLog::Out(__FILE__, __LINE__, __VA_ARGS__)
#else
    #define OUTLOG(...)
#endif