/*****************************************************************************\
	 Snes9x - Portable Super Nintendo Entertainment System (TM) emulator.
				This file is licensed under the Snes9x License.
   For further information, consult the LICENSE file in the root directory.
\*****************************************************************************/

/***********************************************************************************
  SNES9X for Mac OS (c) Copyright John Stiles

  Snes9x for Mac OS X

  (c) Copyright 2001 - 2011  zones
  (c) Copyright 2002 - 2005  107
  (c) Copyright 2002		 PB1400c
  (c) Copyright 2004		 Alexander and Sander
  (c) Copyright 2004 - 2005  Steven Seeger
  (c) Copyright 2005		 Ryan Vogt
  (c) Copyright 2019         Michael Donald Buckley
 ***********************************************************************************/

#import <Cocoa/Cocoa.h>

#include "snes9x.h"
#include "memmap.h"
#include "movie.h"
#include "display.h"

#include <libgen.h>

#include "mac-prefix.h"
#include "mac-dialog.h"
#include "mac-os.h"
#include "mac-stringtools.h"
#include "mac-file.h"

static void AddFolderIcon (NSURL *, const char *);
static NSURL *FindSNESFolder (const char *);
static NSURL *FindApplicationSupportFolder (NSURL *, const char *);
static NSURL *FindCustomFolder (NSURL *, const char *);


void CheckSaveFolder (NSURL *cartURL)
{
	NSString *folderPath = nil;

	switch (saveInROMFolder)
	{
		case 1: // ROM folder
			folderPath = cartURL.URLByDeletingLastPathComponent.path;
			break;

		case 2: // Application Support folder
			return;

		case 4: // Custom folder
			if (saveFolderPath == NULL)
			{
				saveInROMFolder = 2;
				return;
			}

			BOOL isDirectory = NO;
			BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:saveFolderPath isDirectory:&isDirectory];

			if (exists && isDirectory)
			{
				folderPath = saveFolderPath;
			}
			else
			{
				//AppearanceAlert(kAlertCautionAlert, kS9xMacAlertFolderNotFound, kS9xMacAlertFolderNotFoundHint);
				saveInROMFolder = 2;
				return;
			}

			break;
	}

	BOOL writable = [[NSFileManager defaultManager] isWritableFileAtPath:folderPath];

	if (!writable)
	{
		//AppearanceAlert(kAlertCautionAlert, kS9xMacAlertFolderNotWritable, kS9xMacAlertFolderNotWritableHint);
		saveInROMFolder = 2;
		return;
	}
}

static NSURL *FindSNESFolder (const char *folderName)
{
	NSURL		*purl = nil;
	NSString	*fstr = [NSString stringWithUTF8String:folderName];

	purl = [[[NSBundle mainBundle] bundleURL].URLByDeletingLastPathComponent URLByAppendingPathComponent:fstr];

	if (![NSFileManager.defaultManager fileExistsAtPath:purl.path])
	{
		NSError *error = nil;
		if ( [NSFileManager.defaultManager createDirectoryAtURL:purl withIntermediateDirectories:YES attributes:nil error:&error] )
		{
			AddFolderIcon(purl, folderName);
		}
		else
		{
			[[NSAlert alertWithError:error] runModal];
		}
	}

	return purl;
}

static NSURL *FindApplicationSupportFolder (const char *folderName)
{
	NSURL		*purl = nil;
	NSURL		*baseURL = nil;
	NSURL		*s9xURL = nil;
	NSURL		*oldURL = nil;
	NSString	*fstr = [NSString stringWithUTF8String:folderName];

	baseURL = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;

	if (!baseURL)
	{
		return nil;
	}

	s9xURL = [baseURL URLByAppendingPathComponent:@"Snes9x"];
	oldURL = [baseURL URLByAppendingPathComponent:@"SNES9X"];

	if ([NSFileManager.defaultManager fileExistsAtPath:s9xURL.path])
	{
		purl = [s9xURL URLByAppendingPathComponent:fstr];
	}
	else if ([NSFileManager.defaultManager fileExistsAtPath:oldURL.path])
	{
		purl = [oldURL URLByAppendingPathComponent:fstr];
	}

	if (purl == NULL)
	{
		purl = [s9xURL URLByAppendingPathComponent:fstr];
	}

	[NSFileManager.defaultManager createDirectoryAtURL:purl withIntermediateDirectories:YES attributes:nil error:NULL];

	return purl;
}

static NSURL *FindCustomFolder (const char *folderName)
{
	NSURL *purl = nil;

	if (saveFolderPath == NULL)
		return nil;

	purl = [NSURL fileURLWithPath:saveFolderPath];

	if (![NSFileManager.defaultManager fileExistsAtPath:saveFolderPath])
	{
		NSError *error = nil;
		if (![NSFileManager.defaultManager createDirectoryAtPath:saveFolderPath withIntermediateDirectories:YES attributes:nil error:&error])
		{
			[[NSAlert alertWithError:error] runModal];
			return nil;
		}
	}

	purl = [purl URLByAppendingPathComponent:[NSString stringWithUTF8String:folderName]];

	if (![NSFileManager.defaultManager fileExistsAtPath:purl.path])
	{
		NSError *error = nil;
		if ([NSFileManager.defaultManager createDirectoryAtPath:saveFolderPath withIntermediateDirectories:YES attributes:nil error:&error])
		{
			AddFolderIcon(purl, folderName);
		}
		{
			[[NSAlert alertWithError:error] runModal];
			return nil;
		}
	}

	return purl;
}

void ChangeTypeAndCreator (const char *path, OSType type, OSType creator)
{
//	NSError *error = nil;
//	if (![NSFileManager.defaultManager setAttributes:@{NSFileHFSCreatorCode: @(creator), NSFileHFSTypeCode: @(type)} ofItemAtPath:[NSString stringWithUTF8String:path] error:&error])
//	{
//		[[NSAlert alertWithError:error] runModal];
//	}
}

static void AddFolderIcon (NSURL *fref, const char *folderName)
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *filename = [@"folder_" stringByAppendingString:[NSString stringWithUTF8String:folderName]];
	NSURL *imageURL = [bundle URLForResource:filename withExtension:@"icns"];
	NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];

	if ( image != nil )
	{
		[NSWorkspace.sharedWorkspace setIcon:image forFile:fref.path options:0];
	}
}

const char * S9xGetFilename (const char *inExt, enum s9x_getdirtype dirtype)
{
	static int	index = 0;
	static char	filePath[4][PATH_MAX + 1];

	uint32		type;
	char		folderName[16];
	char		drive[_MAX_DRIVE + 1], dir[_MAX_DIR + 1], fname[_MAX_FNAME + 1], ext[_MAX_EXT + 1];
	const char	*p;

	index++;
	if (index > 3)
		index = 0;

	folderName[0] = filePath[index][0] = 0;

	if (strlen(inExt) < 4)
		return (filePath[index]);

	p = inExt + strlen(inExt) - 4;
	type = ((uint32) p[0] << 24) + ((uint32) p[1] << 16) + ((uint32) p[2] << 8) + (uint32) p[3];

	switch (type)
	{
		case '.srm':
		case '.rtc':
			strlcpy(folderName, "SRAMs", sizeof(folderName));
			break;

		case '.frz':
			strlcpy(folderName, "Freezes", sizeof(folderName));
			break;

		case '.spc':
			strlcpy(folderName, "SPCs", sizeof(folderName));
			break;

		case '.cht':
			strlcpy(folderName, "Cheats", sizeof(folderName));
			break;

		case '.ups':
		case '.ips':
			strlcpy(folderName, "Patches", sizeof(folderName));
			break;

		case '.png':
			strlcpy(folderName, "Screenshots", sizeof(folderName));
			break;

		case '.dat':
		case '.out':
		case '.log':
			strlcpy(folderName, "Logs", sizeof(folderName));
			break;

		case '.bio':	// dummy
			strlcpy(folderName, "BIOSes", sizeof(folderName));
			break;
	}

	if (folderName[0] && (saveInROMFolder != 1))
	{
		NSURL *folderURL = nil;
		if (saveInROMFolder == 0)
		{
			folderURL = FindSNESFolder(folderName);
			if (folderURL == nil)
				saveInROMFolder = 2;
		}

		if (saveInROMFolder == 4)
		{
			folderURL = FindCustomFolder(folderName);
			if (folderURL == nil)
				saveInROMFolder = 2;
		
		}

		if (saveInROMFolder == 2)
			folderURL = FindApplicationSupportFolder(folderName);

		if (folderURL != nil)
		{
			_splitpath(Memory.ROMFilename, drive, dir, fname, ext);
			snprintf(filePath[index], PATH_MAX + 1, "%s%s%s%s", folderURL.path.UTF8String, MAC_PATH_SEPARATOR, fname, inExt);
		}
		else
		{
			_splitpath(Memory.ROMFilename, drive, dir, fname, ext);

			strlcat(fname, inExt, sizeof(fname));
			_makepath(filePath[index], drive, dir, fname, "");
		}
	}
	else
	{
		_splitpath(Memory.ROMFilename, drive, dir, fname, ext);

		strlcat(fname, inExt, sizeof(fname));
		_makepath(filePath[index], drive, dir, fname, "");
	}

	return (filePath[index]);
}

const char * S9xGetSPCFilename (void)
{
	char	spcExt[16];

	sprintf(spcExt, ".%03d.spc", (int) spcFileCount);

	spcFileCount++;
	if (spcFileCount == 1000)
		spcFileCount = 0;

	return (S9xGetFilename(spcExt, SPC_DIR));
}

const char * S9xGetPNGFilename (void)
{
	char	pngExt[16];

	sprintf(pngExt, ".%03d.png", (int) pngFileCount);

	pngFileCount++;
	if (pngFileCount == 1000)
		pngFileCount = 0;

	return (S9xGetFilename(pngExt, SCREENSHOT_DIR));
}

const char * S9xGetFreezeFilename (int which)
{
	char	frzExt[16];

	sprintf(frzExt, ".%03d.frz", which);

	return (S9xGetFilename(frzExt, SNAPSHOT_DIR));
}

const char * S9xGetFilenameInc (const char *inExt, enum s9x_getdirtype dirtype)
{
	uint32		type;
	const char	*p;

	if (strlen(inExt) < 4)
		return (NULL);

	p = inExt + strlen(inExt) - 4;
	type = ((uint32) p[0] << 24) + ((uint32) p[1] << 16) + ((uint32) p[2] << 8) + (uint32) p[3];

	switch (type)
	{
		case '.spc':
			return (S9xGetSPCFilename());

		case '.png':
			return (S9xGetPNGFilename());
	}

	return (NULL);
}

bool8 S9xOpenSnapshotFile (const char *fname, bool8 read_only, STREAM *file)
{
	if (read_only)
	{
		if (0 != (*file = OPEN_STREAM(fname, "rb")))
			return (true);
	}
	else
	{
		if (0 != (*file = OPEN_STREAM(fname, "wb")))
			return (true);
	}

	return (false);
}

void S9xCloseSnapshotFile (STREAM file)
{
	CLOSE_STREAM(file);
}

const char * S9xBasename (const char *in)
{
	static char	s[PATH_MAX + 1];

	strlcpy(s, in, sizeof(s));
	s[PATH_MAX] = 0;

	size_t	l = strlen(s);

	for (unsigned int i = 0; i < l; i++)
	{
		if (s[i] < 32 || s[i] >= 127)
			s[i] = '_';
	}

	return (basename(s));
}

const char * S9xGetDirectory (enum s9x_getdirtype dirtype)
{
	static int	index = 0;
	static char	path[4][PATH_MAX + 1];

	char	inExt[16];
	char	drive[_MAX_DRIVE + 1], dir[_MAX_DIR + 1], fname[_MAX_FNAME + 1], ext[_MAX_EXT + 1];

	index++;
	if (index > 3)
		index = 0;

	switch (dirtype)
	{
		case SNAPSHOT_DIR:		strlcpy(inExt, ".frz", sizeof(inExt));	break;
		case SRAM_DIR:			strlcpy(inExt, ".srm", sizeof(inExt));	break;
		case SCREENSHOT_DIR:	strlcpy(inExt, ".png", sizeof(inExt));	break;
		case SPC_DIR:			strlcpy(inExt, ".spc", sizeof(inExt));	break;
		case CHEAT_DIR:			strlcpy(inExt, ".cht", sizeof(inExt));	break;
		case BIOS_DIR:			strlcpy(inExt, ".bio", sizeof(inExt));	break;
		case LOG_DIR:			strlcpy(inExt, ".log", sizeof(inExt));	break;
		default:				strlcpy(inExt, ".xxx", sizeof(inExt));	break;
	}

	_splitpath(S9xGetFilename(inExt, dirtype), drive, dir, fname, ext);
	_makepath(path[index], drive, dir, "", "");

	size_t	l = strlen(path[index]);
	if (l > 1)
		path[index][l - 1] = 0;

	return (path[index]);
}
