<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="Dascore_LibSlash" version="2.0" date="23/11/2008" >
		<Author name="Onni" email="dascore@onni.biz" />
		<Description text="(version 2.0 2008-11-23) Dascore with LibSlash support." />
		<VersionSettings gameVersion="1.4.1" windowsVersion="1.0" savedVariablesVersion="1.0" />
		<Dependencies>
			<Dependency name="Dascore" />
			<Dependency name="LibSlash" />
		</Dependencies>
		<Files>
			<File name="Dascore_LibSlash.lua" />			<!--LibSlash command enabler-->
		</Files>
		<OnInitialize>
			<CallFunction name="Dascore_LibSlash.OnInitialize" />
		</OnInitialize>
		<OnUpdate/>
		<OnShutdown>
		</OnShutdown>
	</UiMod>
</ModuleFile>
