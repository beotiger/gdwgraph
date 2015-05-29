program PEditor;

Uses
  SDLglGDWGraph in '../sdlglgdwgraph.pas', // My VGA-13 API
  PEdit in 'pedit.pas',
  PDefs in 'Pdefs.pas';


{ $R *.res}

{$IFDEF WINDOWS}{ $R peditor.rc}{$ENDIF}

begin
	Main;
end.

