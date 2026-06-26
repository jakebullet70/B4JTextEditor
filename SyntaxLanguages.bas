B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=10.5
@EndOfDesignText@
' Language definitions for syntax highlighting (data, not logic).
' Each language is a Map: name, extensions(List), keywords(List), ci(Boolean=case-insensitive),
' patterns(Map category->regex), optional types(List of type names). Categories: comment, string,
' char, number, annotation, type, keyword. keyword/type come from word lists (or a pattern fallback).
' Regex is plain B4X text (backslashes are literal here, so no double-escaping); a literal double
' quote is built from Chr(34). SyntaxHL turns these into one named-group regex per language.
' These could later be loaded from JSON files in Files\ without changing SyntaxHL - same shape.
Sub Process_Globals
End Sub

Public Sub GetLanguages As List
	Dim langs As List
	langs.Initialize
	langs.Add(LangJava)
	langs.Add(LangPython)
	langs.Add(LangJson)
	langs.Add(LangB4X)
	langs.Add(LangMarkdown)
	Return langs
End Sub

Private Sub Q As String
	Return Chr(34)
End Sub

Private Sub MakeLang (name As String, exts() As String, keywords() As String, ci As Boolean, patterns As Map) As Map
	Dim m As Map
	m.Initialize
	m.Put("name", name)
	m.Put("extensions", ToList(exts))
	m.Put("keywords", ToList(keywords))
	m.Put("ci", ci)
	m.Put("patterns", patterns)
	Return m
End Sub

Private Sub ToList (arr() As String) As List
	Dim l As List
	l.Initialize
	For Each s As String In arr
		l.Add(s)
	Next
	Return l
End Sub

Private Sub LangJava As Map
	Dim p As Map
	p.Initialize
	p.Put("comment", "//[^" & Chr(10) & "]*|/\*[\s\S]*?\*/")
	p.Put("string", Q & "(\\.|[^" & Q & "\\])*" & Q)
	p.Put("char", "'(\\.|[^'\\])'")
	p.Put("annotation", "@\w+")
	p.Put("number", "\b\d+(\.\d+)?\b")
	Dim m As Map = MakeLang("Java", Array As String("java"), Array As String( _
		"abstract","assert","break","case","catch","class","const", _
		"continue","default","do","else","enum","extends","final","finally", _
		"for","goto","if","implements","import","instanceof","interface","native", _
		"new","package","private","protected","public","return","static","strictfp", _
		"super","switch","synchronized","this","throw","throws","transient","try", _
		"volatile","while","true","false","null"), False, p)
	m.Put("types", ToList(Array As String( _
		"boolean","byte","char","short","int","long","float","double","void", _
		"String","Object","Integer","Long","Double","Float","Boolean","Byte","Short","Character", _
		"Number","List","Map","Set","ArrayList","HashMap","Exception")))
	Return m
End Sub

Private Sub LangPython As Map
	Dim p As Map
	p.Initialize
	p.Put("comment", "#[^" & Chr(10) & "]*")
	p.Put("string", Q & "(\\.|[^" & Q & "\\])*" & Q & "|'(\\.|[^'\\])*'")
	p.Put("annotation", "@\w+")
	p.Put("number", "\b\d+(\.\d+)?\b")
	Dim m As Map = MakeLang("Python", Array As String("py"), Array As String( _
		"and","as","assert","break","class","continue","def","del","elif","else","except", _
		"finally","for","from","global","if","import","in","is","lambda","nonlocal","not","or", _
		"pass","raise","return","try","while","with","yield","None","True","False","self"), False, p)
	m.Put("types", ToList(Array As String( _
		"int","float","str","bool","bytes","bytearray","list","dict","tuple","set","frozenset", _
		"object","type","complex")))
	Return m
End Sub

Private Sub LangJson As Map
	Dim p As Map
	p.Initialize
	p.Put("string", Q & "(\\.|[^" & Q & "\\])*" & Q)
	p.Put("number", "-?\b\d+(\.\d+)?([eE][+-]?\d+)?\b")
	Return MakeLang("JSON", Array As String("json"), Array As String("true","false","null"), False, p)
End Sub

Private Sub LangB4X As Map
	Dim p As Map
	p.Initialize
	p.Put("comment", "'[^" & Chr(10) & "]*")
	p.Put("string", Q & "[^" & Q & "]*" & Q)
	p.Put("number", "\b\d+(\.\d+)?\b")
	Dim m As Map = MakeLang("B4X", Array As String("bas","b4x"), Array As String( _
		"Sub","End","If","Then","Else","ElseIf","For","Next","Do","While","Loop","Select","Case", _
		"Dim","As","Return","True","False","Null","And","Or","Not","Xor","Private","Public", _
		"Type","Class_Globals","Process_Globals","Wait","Continue","Exit","To","Step","Each", _
		"Const","CallSub","Initialize"), True, p)
	m.Put("types", ToList(Array As String( _
		"Int","Float","Double","String","Boolean","Byte","Long","Short","Object","List","Map", _
		"JavaObject","StringBuilder")))
	Return m
End Sub

Private Sub LangMarkdown As Map
	Dim BT As String = Chr(96)        ' backtick
	Dim NL As String = Chr(10)
	Dim p As Map
	p.Initialize
	' HTML comments and blockquotes.
	p.Put("comment", "<!--[\s\S]*?-->|(?m:^\s*>[^" & NL & "]*)")
	' Headings (whole line). keyword has no word list here, so SyntaxHL uses this pattern.
	p.Put("keyword", "(?m:^#{1,6}[^" & NL & "]*)")
	' Fenced and inline code.
	p.Put("string", BT & "{3}[\s\S]*?" & BT & "{3}|" & BT & "[^" & BT & NL & "]+" & BT)
	' Bold.
	p.Put("annotation", "\*\*[^*" & NL & "]+\*\*|__[^_" & NL & "]+__")
	' Links [text](url) coloured as the type category.
	p.Put("type", "\[[^\]" & NL & "]*\]\([^)" & NL & "]*\)")
	Return MakeLang("Markdown", Array As String("md","markdown"), Array As String(), False, p)
End Sub
