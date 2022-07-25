/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
#include "svdpi.h"
#include <cstring>


#if (defined(_MSC_VER) || defined(__MINGW32__) || defined(__CYGWIN__))
#define DPI_DLLISPEC __declspec(dllimport)
#define DPI_DLLESPEC __declspec(dllexport)
#else
#define DPI_DLLISPEC
#define DPI_DLLESPEC
#endif


extern "C"
{
	DPI_DLLISPEC extern void  DPISetMode(int mode) ;
	DPI_DLLISPEC extern int   DPIGetMode() ; 
	DPI_DLLISPEC extern void  DPIAllocateExportedFunctions(int size) ;
	DPI_DLLISPEC extern void  DPIAddExportedFunction(int index, const char* value) ;
	DPI_DLLISPEC extern void  DPIAllocateSVCallerName(int index, const char* y) ;
	DPI_DLLISPEC extern void  DPISetCallerName(int index, const char* y) ;
	DPI_DLLISPEC extern void  DPISetCallerLine(int index, unsigned int y) ;
	DPI_DLLISPEC extern void  DPISetCallerOffset(int index, int y) ;
	DPI_DLLISPEC extern void  DPIAllocateDPIScopes(int size) ;
	DPI_DLLISPEC extern void  DPISetDPIScopeFunctionName(int index, const char* y) ;
	DPI_DLLISPEC extern void  DPISetDPIScopeHierarchy(int index, const char* y) ;
	DPI_DLLISPEC extern void  DPIRelocateDPIScopeIP(int index, char* IP) ;
	DPI_DLLISPEC extern void  DPIAddDPIScopeAccessibleFunction(int index, unsigned int y) ;
	DPI_DLLISPEC extern void  DPIFlushAll() ;
	DPI_DLLISPEC extern void  DPIVerifyScope() ;
	DPI_DLLISPEC extern char* DPISignalHandle(char* sigHandle, int length) ;
	DPI_DLLISPEC extern char* DPIMalloc(unsigned noOfBytes) ;
	DPI_DLLISPEC extern void  DPITransactionAuto(char* srcValue, unsigned int startIndex, unsigned int endIndex, char* net) ;
	DPI_DLLISPEC extern void  DPIScheduleTransactionBlocking(char* var, char* driver, char* src, unsigned setback, unsigned lenMinusOnne) ;
	DPI_DLLISPEC extern void  DPIMemsetSvToDpi(char* dst, char* src, int numCBytes, int is2state) ;
	DPI_DLLISPEC extern void  DPIMemsetDpiToSv(char* dst, char* src, int numCBytes, int is2state) ;
	DPI_DLLISPEC extern void  DPIMemsetSvLogic1ToDpi(char* dst, char* src) ;
	DPI_DLLISPEC extern void  DPIMemsetDpiToSvLogic1(char* dst, char* src) ;
	DPI_DLLISPEC extern void  DPIMemsetDpiToSvUnpackedLogic(char* dst, char* src, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetDpiToSvUnpackedLogicWithPackedDim(char* dst, char* src, int pckedSz, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetSvToDpiUnpackedLogic(char* dst, char* src, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetSvToDpiUnpackedLogicWithPackedDim(char* dst, char* src, int pckdSz, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetDpiToSvUnpackedBit(char* dst, char* src, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetDpiToSvUnpackedBitWithPackedDim(char* dst, char* src, int pckdSz, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetSvToDpiUnpackedBit(char* dst, char* src, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPIMemsetSvToDpiUnpackedBitWithPackedDim(char* dst, char* src, int pckdSz, int* numRshift, int* shift) ;
	DPI_DLLISPEC extern void  DPISetFuncName(const char* funcName) ;
	DPI_DLLISPEC extern int   staticScopeCheck(const char* calledFunction) ;
	DPI_DLLISPEC extern void  DPIAllocateSVCallerInfo(int size) ;
	DPI_DLLISPEC extern void* DPICreateContext(int scopeId, char* IP, int callerIdx);
	DPI_DLLISPEC extern void* DPIGetCurrentContext();
	DPI_DLLISPEC extern void  DPISetCurrentContext(void*);
	DPI_DLLISPEC extern void  DPIRemoveContext(void*);
	DPI_DLLISPEC extern int   svGetScopeStaticId();
	DPI_DLLISPEC extern char* svGetScopeIP();
	DPI_DLLISPEC extern unsigned DPIGetUnpackedSizeFromSVOpenArray(svOpenArray*);
	DPI_DLLISPEC extern unsigned DPIGetConstraintSizeFromSVOpenArray(svOpenArray*, int);
	DPI_DLLISPEC extern int   topOffset() ;
	DPI_DLLISPEC extern char* DPIInitializeFunction(char* p, unsigned size, long long offset) ;
	DPI_DLLISPEC extern void  DPIInvokeFunction(char* processPtr, char* SP, void* func, char* IP) ;
	DPI_DLLISPEC extern void  DPIDeleteFunctionInvocation(char* SP) ;
	DPI_DLLISPEC extern void  DPISetTaskScopeId(int scopeId) ;
	DPI_DLLISPEC extern void  DPISetTaskCaller(int index) ;
	DPI_DLLISPEC extern int   DPIGetTaskCaller() ;
	DPI_DLLISPEC extern char* DPIInitializeTask(long long subprogInDPOffset, char* scopePropInIP, unsigned size, char* parentBlock) ;
	DPI_DLLISPEC extern void  DPIInvokeTask(long long subprogInDPOffset, char* SP, void* func, char* IP) ;
	DPI_DLLISPEC extern void  DPIDeleteTaskInvocation(char* SP) ;
	DPI_DLLISPEC extern void* DPICreateTaskContext(int (*wrapper)(char*, char*, char*), char* DP, char* IP, char* SP, size_t stackSz) ;
	DPI_DLLISPEC extern void  DPIRemoveTaskContext(void*) ;
	DPI_DLLISPEC extern void  DPICallCurrentContext() ;
	DPI_DLLISPEC extern void  DPIYieldCurrentContext() ;
	DPI_DLLISPEC extern void* DPIGetCurrentTaskContext() ;
	DPI_DLLISPEC extern int   DPIRunningInNewContext() ;
	DPI_DLLISPEC extern void  DPISetCurrentTaskContext(void* x) ;
}

namespace XILINX_DPI { 

	void dpiInitialize()
	{
		DPIAllocateSVCallerInfo(19) ;
		DPISetCallerName(0, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(0, 212) ;
		DPISetCallerOffset(0, 7896) ;
		DPISetCallerName(1, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(1, 213) ;
		DPISetCallerOffset(1, 7896) ;
		DPISetCallerName(2, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(2, 240) ;
		DPISetCallerOffset(2, 8168) ;
		DPISetCallerName(3, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(3, 241) ;
		DPISetCallerOffset(3, 8168) ;
		DPISetCallerName(4, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(4, 242) ;
		DPISetCallerOffset(4, 8168) ;
		DPISetCallerName(5, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(5, 243) ;
		DPISetCallerOffset(5, 8168) ;
		DPISetCallerName(6, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(6, 245) ;
		DPISetCallerOffset(6, 8168) ;
		DPISetCallerName(7, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(7, 246) ;
		DPISetCallerOffset(7, 8168) ;
		DPISetCallerName(8, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(8, 247) ;
		DPISetCallerOffset(8, 8168) ;
		DPISetCallerName(9, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(9, 249) ;
		DPISetCallerOffset(9, 8168) ;
		DPISetCallerName(10, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(10, 250) ;
		DPISetCallerOffset(10, 8168) ;
		DPISetCallerName(11, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(11, 251) ;
		DPISetCallerOffset(11, 8168) ;
		DPISetCallerName(12, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(12, 253) ;
		DPISetCallerOffset(12, 8168) ;
		DPISetCallerName(13, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(13, 254) ;
		DPISetCallerOffset(13, 8168) ;
		DPISetCallerName(14, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(14, 255) ;
		DPISetCallerOffset(14, 8168) ;
		DPISetCallerName(15, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(15, 257) ;
		DPISetCallerOffset(15, 8168) ;
		DPISetCallerName(16, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(16, 258) ;
		DPISetCallerOffset(16, 8168) ;
		DPISetCallerName(17, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(17, 259) ;
		DPISetCallerOffset(17, 8168) ;
		DPISetCallerName(18, "C:/Users/14991/Desktop/4summer/ECE4700J/final project/dev/VE470_Superscalar/testbench/testbench.sv") ;
		DPISetCallerLine(18, 315) ;
		DPISetCallerOffset(18, 8168) ;
		DPIAllocateDPIScopes(4) ;
		DPISetDPIScopeFunctionName(0, "print_header") ;
		DPISetDPIScopeHierarchy(0, "$unit_sys_defs_svh_3471327653") ;
		DPIRelocateDPIScopeIP(0, (char*)(0x33390)) ;
		DPISetDPIScopeFunctionName(1, "print_cycles") ;
		DPISetDPIScopeHierarchy(1, "$unit_sys_defs_svh_3471327653") ;
		DPIRelocateDPIScopeIP(1, (char*)(0x33390)) ;
		DPISetDPIScopeFunctionName(2, "print_stage") ;
		DPISetDPIScopeHierarchy(2, "$unit_sys_defs_svh_3471327653") ;
		DPIRelocateDPIScopeIP(2, (char*)(0x33390)) ;
		DPISetDPIScopeFunctionName(3, "print_close") ;
		DPISetDPIScopeHierarchy(3, "$unit_sys_defs_svh_3471327653") ;
		DPIRelocateDPIScopeIP(3, (char*)(0x33390)) ;
	}

}


extern "C" {
	void iki_initialize_dpi()
	{ XILINX_DPI::dpiInitialize() ; } 
}


extern "C" {

	extern void print_header(const char* arg0) ;
	extern void print_cycles() ;
	extern void print_stage(const char* arg0, int arg1, int arg2, int arg3) ;
	extern void print_close() ;
}


extern "C" {
	void Dpi_wrapper_print_header(char *GlobalDP, char *IP, char *SP)
	{
DPISetMode(1) ; // Function chain mode : with or without context 

		    /******* Preserve Context Info *******/ 
		char *ptrToSP  = SP; 
		ptrToSP = ptrToSP + 168; 
		int scopeIdx = *((int*)ptrToSP);
		ptrToSP = (char*)((int*)ptrToSP + 1); 
		int callerIdx = *((int*)ptrToSP);
		void* funcContext = DPICreateContext(scopeIdx, IP, callerIdx);
		(*((void**)(SP + 168))) = funcContext;
		DPISetCurrentContext(*(void**)(SP + 168));
		ptrToSP = (char*)((int*)ptrToSP + 1); 

		    /******* Convert SV types to DPI-C Types *******/ 

		    /******* Create and populate DPI-C types for the arguments *******/ 

const char emptyStrLiteral = '\0';
		ptrToSP = SP + 336 ; 
		const char* cObj0;
		cObj0 = *(char**)ptrToSP == 0? &emptyStrLiteral : *(char**)ptrToSP;
		ptrToSP = ptrToSP + 8; 

		    /******* Done Conversion of SV types to DPI-C Types *******/ 
		    /******* Call the DPI-C function *******/ 
		DPISetFuncName("print_header");
		fflush(stdout); fflush(stderr);
		print_header(cObj0);
		DPIRemoveContext(funcContext);
		fflush(stdout); fflush(stderr);
		DPISetFuncName(0);
		/****** Subprogram Debug : Pop the Call Stack entry for this function invocation  ******/
		iki_vlog_function_callstack_update(SP); 
		return;
	}
	void Dpi_wrapper_print_cycles(char *GlobalDP, char *IP, char *SP)
	{
DPISetMode(1) ; // Function chain mode : with or without context 

		    /******* Preserve Context Info *******/ 
		char *ptrToSP  = SP; 
		ptrToSP = ptrToSP + 168; 
		int scopeIdx = *((int*)ptrToSP);
		ptrToSP = (char*)((int*)ptrToSP + 1); 
		int callerIdx = *((int*)ptrToSP);
		void* funcContext = DPICreateContext(scopeIdx, IP, callerIdx);
		(*((void**)(SP + 168))) = funcContext;
		DPISetCurrentContext(*(void**)(SP + 168));
		ptrToSP = (char*)((int*)ptrToSP + 1); 

		    /******* Convert SV types to DPI-C Types *******/ 

		    /******* Create and populate DPI-C types for the arguments *******/ 

		    /******* Done Conversion of SV types to DPI-C Types *******/ 
		    /******* Call the DPI-C function *******/ 
		DPISetFuncName("print_cycles");
		fflush(stdout); fflush(stderr);
		print_cycles();
		DPIRemoveContext(funcContext);
		fflush(stdout); fflush(stderr);
		DPISetFuncName(0);
		/****** Subprogram Debug : Pop the Call Stack entry for this function invocation  ******/
		iki_vlog_function_callstack_update(SP); 
		return;
	}
	void Dpi_wrapper_print_stage(char *GlobalDP, char *IP, char *SP)
	{
DPISetMode(1) ; // Function chain mode : with or without context 

		    /******* Preserve Context Info *******/ 
		char *ptrToSP  = SP; 
		ptrToSP = ptrToSP + 168; 
		int scopeIdx = *((int*)ptrToSP);
		ptrToSP = (char*)((int*)ptrToSP + 1); 
		int callerIdx = *((int*)ptrToSP);
		void* funcContext = DPICreateContext(scopeIdx, IP, callerIdx);
		(*((void**)(SP + 168))) = funcContext;
		DPISetCurrentContext(*(void**)(SP + 168));
		ptrToSP = (char*)((int*)ptrToSP + 1); 

		    /******* Convert SV types to DPI-C Types *******/ 

		    /******* Create and populate DPI-C types for the arguments *******/ 

const char emptyStrLiteral = '\0';
		ptrToSP = SP + 336 ; 
		const char* cObj0;
		cObj0 = *(char**)ptrToSP == 0? &emptyStrLiteral : *(char**)ptrToSP;
		ptrToSP = ptrToSP + 8; 

		ptrToSP = SP + 520 ; 
		int cObj1;
		DPIMemsetSvToDpi( (char*)(&cObj1), ptrToSP, 4, 1 );
		ptrToSP = ptrToSP + 8; 

		ptrToSP = SP + 704 ; 
		int cObj2;
		DPIMemsetSvToDpi( (char*)(&cObj2), ptrToSP, 4, 1 );
		ptrToSP = ptrToSP + 8; 

		ptrToSP = SP + 888 ; 
		int cObj3;
		DPIMemsetSvToDpi( (char*)(&cObj3), ptrToSP, 4, 1 );
		ptrToSP = ptrToSP + 8; 

		    /******* Done Conversion of SV types to DPI-C Types *******/ 
		    /******* Call the DPI-C function *******/ 
		DPISetFuncName("print_stage");
		fflush(stdout); fflush(stderr);
		print_stage(cObj0, cObj1, cObj2, cObj3);
		DPIRemoveContext(funcContext);
		fflush(stdout); fflush(stderr);
		DPISetFuncName(0);
		/****** Subprogram Debug : Pop the Call Stack entry for this function invocation  ******/
		iki_vlog_function_callstack_update(SP); 
		return;
	}
	void Dpi_wrapper_print_close(char *GlobalDP, char *IP, char *SP)
	{
DPISetMode(1) ; // Function chain mode : with or without context 

		    /******* Preserve Context Info *******/ 
		char *ptrToSP  = SP; 
		ptrToSP = ptrToSP + 168; 
		int scopeIdx = *((int*)ptrToSP);
		ptrToSP = (char*)((int*)ptrToSP + 1); 
		int callerIdx = *((int*)ptrToSP);
		void* funcContext = DPICreateContext(scopeIdx, IP, callerIdx);
		(*((void**)(SP + 168))) = funcContext;
		DPISetCurrentContext(*(void**)(SP + 168));
		ptrToSP = (char*)((int*)ptrToSP + 1); 

		    /******* Convert SV types to DPI-C Types *******/ 

		    /******* Create and populate DPI-C types for the arguments *******/ 

		    /******* Done Conversion of SV types to DPI-C Types *******/ 
		    /******* Call the DPI-C function *******/ 
		DPISetFuncName("print_close");
		fflush(stdout); fflush(stderr);
		print_close();
		DPIRemoveContext(funcContext);
		fflush(stdout); fflush(stderr);
		DPISetFuncName(0);
		/****** Subprogram Debug : Pop the Call Stack entry for this function invocation  ******/
		iki_vlog_function_callstack_update(SP); 
		return;
	}
}


extern "C" {
}

