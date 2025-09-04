program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Login},
  Unit2 in 'Unit2.pas' {Home},
  Unit3 in 'Unit3.pas' {DetaljiNaloga},
  Unit4 in 'Unit4.pas' {Uputstvo},
  Unit5 in 'Unit5.pas' {Izvestaj};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLogin, Login);
  Application.CreateForm(THome, Home);
  Application.CreateForm(TDetaljiNaloga, DetaljiNaloga);
  Application.CreateForm(TUputstvo, Uputstvo);
  Application.CreateForm(TIzvestaj, Izvestaj);
  Application.Run;
end.
