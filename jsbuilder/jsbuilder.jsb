<?xml version="1.0" encoding="utf-8"?>
<project path="" name="" author="" version="" copyright="" output="$project\jsbuild-result" source="False" source-dir="$output\source" minify="False" min-dir="$output\build" doc="False" doc-dir="$output\docs" master="true" master-file="$output\yui-ext.js" zip="true" zip-file="$output\yuo-ext.$version.zip">
  <directory name="../public" />
  <file name="..\public\javascripts\prototype.js" path="javascripts" />
  <file name="..\public\javascripts\effects.js" path="javascripts" />
  <file name="..\public\javascripts\application.js" path="javascripts" />
  <file name="..\public\javascripts\fastinit.js" path="javascripts" />
  <file name="..\public\javascripts\control_tabs.js" path="javascripts" />
  <file name="..\public\javascripts\control_select_multiple.js" path="javascripts" />
  <file name="..\public\javascripts\calendar_date_select.js" path="javascripts" />
  <file name="..\public\javascripts\calendar_date_select_format_hyphen_ampm.js" path="javascripts" />
  <target name="js in layout/main" file="$output\main.js" debug="False" shorthand="False" shorthand-list="YAHOO.util.Dom.setStyle&#xD;&#xA;YAHOO.util.Dom.getStyle&#xD;&#xA;YAHOO.util.Dom.getRegion&#xD;&#xA;YAHOO.util.Dom.getViewportHeight&#xD;&#xA;YAHOO.util.Dom.getViewportWidth&#xD;&#xA;YAHOO.util.Dom.get&#xD;&#xA;YAHOO.util.Dom.getXY&#xD;&#xA;YAHOO.util.Dom.setXY&#xD;&#xA;YAHOO.util.CustomEvent&#xD;&#xA;YAHOO.util.Event.addListener&#xD;&#xA;YAHOO.util.Event.getEvent&#xD;&#xA;YAHOO.util.Event.getTarget&#xD;&#xA;YAHOO.util.Event.preventDefault&#xD;&#xA;YAHOO.util.Event.stopEvent&#xD;&#xA;YAHOO.util.Event.stopPropagation&#xD;&#xA;YAHOO.util.Event.stopEvent&#xD;&#xA;YAHOO.util.Anim&#xD;&#xA;YAHOO.util.Motion&#xD;&#xA;YAHOO.util.Connect.asyncRequest&#xD;&#xA;YAHOO.util.Connect.setForm&#xD;&#xA;YAHOO.util.Dom&#xD;&#xA;YAHOO.util.Event">
    <include name="..\public\javascripts\application.js" />
    <include name="..\public\javascripts\controls.js" />
    <include name="..\public\javascripts\effects.js" />
    <include name="..\public\javascripts\fastinit.js" />
    <include name="..\public\javascripts\control_tabs.js" />
    <include name="..\public\javascripts\control_select_multiple.js" />
  </target>
  <file name="..\public\javascripts\controls.js" path="javascripts" />
</project>