#include "RetroAchievements.h"

#include "RA_BuildVer.h"

#include "wsnes9x.h"
#include "../snes9x.h"
#include "../memmap.h"

static size_t s_nSRAMBytes = 0;

static void CauseUnpause() {}
static void CausePause() {}

static int GetMenuItemIndex(HMENU hMenu, const char* pItemName)
{
	int nIndex = 0;
	char pBuffer[256];

	while (nIndex < GetMenuItemCount(hMenu))
	{
		if (GetMenuStringA(hMenu, nIndex, pBuffer, sizeof(pBuffer) - 1, MF_BYPOSITION))
		{
			if (!strcmp(pItemName, pBuffer))
				return nIndex;
		}
		nIndex++;
	}

	return -1;
}

static void RebuildMenu()
{
	HMENU hMainMenu = GetMenu(GUI.hWnd);
	if (!hMainMenu)
		return;

	// if RetroAchievements submenu exists, destroy it
	int index = GetMenuItemIndex(hMainMenu, "&RetroAchievements");
	if (index >= 0)
		DeleteMenu(hMainMenu, index, MF_BYPOSITION);

	// append RetroAchievements menu
	AppendMenu(hMainMenu, MF_POPUP | MF_STRING, (UINT_PTR)RA_CreatePopupMenu(), TEXT("&RetroAchievements"));

	// repaint
	DrawMenuBar(GUI.hWnd);
}

static void GetEstimatedGameTitle(char* sNameOut)
{
	sprintf_s(sNameOut, 64, "%s", Memory.ROMName ? &Memory.ROMName[0] : "");
}

static void ResetEmulator() {}
static void LoadROM(const char* sFullPath) {}

void RA_Init()
{
	// initialize the DLL
	RA_Init(GUI.hWnd, RA_Snes9x, RASNES9X_VERSION);
	RA_SetConsoleID(SNES);

	// provide callbacks to the DLL
	RA_InstallSharedFunctions(NULL, CauseUnpause, CausePause, RebuildMenu, GetEstimatedGameTitle, ResetEmulator, LoadROM);

	// add a placeholder menu item and start the login process - menu will be updated when login completes
	RebuildMenu();
	RA_AttemptLogin(true);

	// ensure titlebar text matches expected format
	RA_UpdateAppTitle("");
}

static unsigned char ByteReader(size_t nOffs)
{
	return Memory.RAM[nOffs % 0x20000];
}

static void ByteWriter(size_t nOffs, unsigned int nVal)
{
	if (nOffs < 0x20000)
		Memory.RAM[nOffs] = nVal;
}

static unsigned char ByteReaderSRAM(size_t nOffs)
{
	return Memory.SRAM[nOffs % s_nSRAMBytes];
}

static void ByteWriterSRAM( size_t nOffs, unsigned int nVal )
{
	if (nOffs < s_nSRAMBytes)
		Memory.SRAM[nOffs] = nVal;
}

void RA_OnLoadNewRom()
{
	s_nSRAMBytes = Memory.SRAMSize ? (1 << (Memory.SRAMSize + 3)) * 128 : 0;
	if (s_nSRAMBytes > 0x20000)
		s_nSRAMBytes = 0x20000;

	RA_ClearMemoryBanks();
	RA_InstallMemoryBank(0, ByteReader, ByteWriter, 0x20000);
	RA_InstallMemoryBank(1, ByteReaderSRAM, ByteWriterSRAM, s_nSRAMBytes);

	RA_OnLoadNewRom(Memory.ROM, Memory.CalculatedSize);
}
