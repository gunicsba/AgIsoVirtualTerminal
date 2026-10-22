"""Writes AgISOVirtualTerminal.jucer for JUCE's Android Studio exporter.

JUCE's CMake API cannot target Android, so the Android build goes through the Projucer. The VT's
own sources are read from the target_sources() list in CMakeLists.txt, so the two builds compile
the same files. AgIsoStack++ is compiled from source, with the Proemion CANlink as its only driver,
because a phone has no CAN hardware of its own.

Usage: python make_jucer.py <AgIsoStack++ checkout> <JUCE modules folder>
"""
import os
import re
import sys
from xml.sax.saxutils import quoteattr

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)

STACK_HARDWARE_SOURCES = ["can_hardware_interface.cpp", "proemion_canlink_interface.cpp"]
MODULES = ["juce_core", "juce_events", "juce_data_structures", "juce_graphics", "juce_gui_basics", "juce_gui_extra",
           "juce_audio_basics", "juce_audio_devices", "juce_audio_formats", "juce_audio_processors", "juce_audio_utils"]
DEFINES = ["JUCE_WEB_BROWSER=0", "JUCE_USE_CURL=0", "ISOBUS_PROEMION_AVAILABLE=1", "CAN_PORT_MAXIMUM_VALUE=4"]


def rel(path, start=HERE):
	return os.path.relpath(path, start).replace("\\", "/")


def vt_sources():
	cmake = open(os.path.join(REPO, "CMakeLists.txt"), encoding="utf-8").read()
	block = re.search(r"target_sources\(\s*AgISOVirtualTerminal\s+PRIVATE(.*?)\)", cmake, re.S).group(1)
	return [os.path.join(REPO, s) for s in re.findall(r'"?(src/[^"\s]+\.cpp)"?', block)]


def stack_sources(stack):
	files = []
	for folder in ("isobus/src", "utility/src"):
		directory = os.path.join(stack, folder)
		files += [os.path.join(directory, f) for f in sorted(os.listdir(directory)) if f.endswith(".cpp")]
	files += [os.path.join(stack, "hardware_integration/src", f) for f in STACK_HARDWARE_SOURCES]
	return files


def file_items(paths, prefix):
	return "\n".join(
	  '      <FILE id="{0}{1}" name={2} compile="1" resource="0" file={3}/>'.format(prefix, i, quoteattr(os.path.basename(p)), quoteattr(rel(p)))
	  for i, p in enumerate(paths))


def main():
	stack = os.path.abspath(sys.argv[1])
	modules = os.path.abspath(sys.argv[2]).replace("\\", "/")
	headers = [os.path.join(REPO, "include"), os.path.join(HERE, "generated")] + \
	          [os.path.join(stack, d, "include") for d in ("isobus", "utility", "hardware_integration")]
	# The Projucer takes header search paths relative to the exporter's folder, not to the .jucer
	header_path = ";".join(rel(h, os.path.join(HERE, "Builds", "Android")) for h in headers)

	jucer = """<?xml version="1.0" encoding="UTF-8"?>

<JUCERPROJECT id="AgIsoVT" name="AgISOVirtualTerminal" projectType="guiapp" useAppConfig="0"
              addUsingNamespaceToJuceHeader="1" jucerFormatVersion="1" version="1.6.0"
              companyName="Open-Agriculture" companyWebsite="https://github.com/Open-Agriculture"
              bundleIdentifier="com.openagriculture.agisovirtualterminal" cppLanguageStandard="17"
              defines={defines}>
  <MAINGROUP id="main" name="AgISOVirtualTerminal">
    <GROUP id="vt" name="Source">
{vt}
      <FILE id="gitc" name="git.c" compile="1" resource="0" file="generated/git.c"/>
      <FILE id="icon" name="smallLogo.png" compile="0" resource="0" file={icon}/>
    </GROUP>
    <GROUP id="stack" name="AgIsoStack">
{stack}
    </GROUP>
  </MAINGROUP>
  <MODULES>
{modules}
  </MODULES>
  <JUCEOPTIONS JUCE_WEB_BROWSER="0" JUCE_USE_CURL="0"/>
  <EXPORTFORMATS>
    <ANDROIDSTUDIO targetFolder="Builds/Android" bigIcon="icon" androidMinimumSDK="24" androidTargetSDK="35"
                   androidInternetNeeded="1" androidScreenOrientation="landscape" androidVersionCode="1">
      <CONFIGURATIONS>
        <CONFIGURATION isDebug="1" name="Debug" headerPath={headers} androidArchitectures="arm64-v8a armeabi-v7a"/>
        <CONFIGURATION isDebug="0" name="Release" headerPath={headers} optimisation="3" androidArchitectures="arm64-v8a armeabi-v7a"/>
      </CONFIGURATIONS>
      <MODULEPATHS>
{modulepaths}
      </MODULEPATHS>
    </ANDROIDSTUDIO>
  </EXPORTFORMATS>
</JUCERPROJECT>
""".format(defines=quoteattr("\n".join(DEFINES)),
	           vt=file_items(vt_sources(), "vt"),
	           icon=quoteattr(rel(os.path.join(REPO, "doc/smallLogo.png"))),
	           stack=file_items(stack_sources(stack), "st"),
	           modules="\n".join('    <MODULE id="{0}" showAllCode="1" useLocalCopy="0" useGlobalPath="0"/>'.format(m) for m in MODULES),
	           headers=quoteattr(header_path),
	           modulepaths="\n".join('        <MODULEPATH id="{0}" path={1}/>'.format(m, quoteattr(modules)) for m in MODULES))

	with open(os.path.join(HERE, "AgISOVirtualTerminal.jucer"), "w", encoding="utf-8", newline="\n") as out:
		out.write(jucer)
	print("wrote AgISOVirtualTerminal.jucer: {0} VT sources, {1} AgIsoStack++ sources".format(len(vt_sources()), len(stack_sources(stack))))


if __name__ == "__main__":
	main()
