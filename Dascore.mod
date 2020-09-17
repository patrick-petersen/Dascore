<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="Dascore" version="2.0" date="23/11/2008" >
		<Author name="Onni" email="dascore@onni.biz" />
		<Description text="(version 2.0 2008-11-23) Shows saved scenario results and custom stats." />
		<VersionSettings gameVersion="1.4.1" windowsVersion="1.0" savedVariablesVersion="1.0" />
		<Dependencies>
			<Dependency name="EASystem_Utils" />
			<Dependency name="EA_ScenarioSummaryWindow" />
		</Dependencies>
		<Files>
			<File name="Dascore.lua" />			<!--Addon initialization,  events, hooks, QueueButton-->
			<File name="DascoreFunc.lua" />	<!--Functions: dynamic options, misc -->
			<File name="DascoreResu.lua" />	<!--Results data saving and loading, combat log importing -->
			<File name="DascoreWin1.xml" />	<!--Results list window -->
			<File name="DascoreWin2.xml" />	<!--Extra scenario data window -->
			<File name="DascorePars.lua" />	<!--"default-parser-addon" to this addon -->
		</Files>
		<SavedVariables>
			<SavedVariable name="DascoreSavedVariables" />
		</SavedVariables>
		<OnInitialize>
			<CallFunction name="Dascore.OnInitialize" />
			<CallFunction name="DascoreWin1.OnInitialize" />
			<CallFunction name="DascoreWin2.OnInitialize" />
			<CallFunction name="DascorePars.ParserInit" />
		</OnInitialize>
		<OnUpdate/>
		<OnShutdown>
		</OnShutdown>
	</UiMod>
</ModuleFile>
