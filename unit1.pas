unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Windows, fgl;

type
  TWindowItem = class
  public
    Title: String;
    Handle: HWND;
  end;
  TWindowList = specialize TFPGObjectList<TWindowItem>;

  TShortcut = record
    Key: Word;
    KeyName: String;
    State: Boolean;
  end;

  TForm1 = class(TForm)
    Button1: TButton;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  public
    WindowList: TWindowList;
    LockShortcut: TShortcut;
    ActiveWindowShortcut: TShortcut;
    LockState: Boolean;
    procedure RefreshWidnows;
    function GetSelectedWindow: TWindowItem;
    procedure SetLockShortcut(const Key: Word);
    procedure SetActiveWindowShortcut(const Key: Word);
    procedure OnActiveWindowShortcutDown;
    procedure OnActiveWindowShortcutUp;
    procedure OnLockShortcutDown;
    procedure OnLockShortcutUp;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function EnumWidnwosCallback(WindowHandle: HWND; Param: LPARAM): WINBOOL; stdcall;
  var WindowTitle: array[0..255] of AnsiChar;
  var WindowTitleLength: Integer;
  var WindowItem: TWindowItem;
begin
  WindowTitleLength := GetWindowTextA(WindowHandle, @WindowTitle, 255);
  if WindowTitleLength > 0 then
  begin
    WindowItem := TWindowItem.Create;
    WindowItem.Title := WindowTitle;
    WindowItem.Handle := WindowHandle;
    TForm1(Param).WindowList.Add(WindowItem);
  end;
  Result := TRUE;
end;

function SortWindows(const Item1, Item2: TWindowItem): Integer;
begin
  Result := CompareStr(Item1.Title, Item2.Title);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  RefreshWidnows;
end;

procedure TForm1.Edit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  SetLockShortcut(Key);
end;

procedure TForm1.Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  SetActiveWindowShortcut(Key);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  WindowList.Free;
  ClipCursor(nil);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  WindowList := TWindowList.Create();
  SetLockShortcut(120);
  SetActiveWindowShortcut(115);
  LockState := False;
  RefreshWidnows;
  Timer1.Enabled := True;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
  var NewState: Boolean;
  var Window: TWindowItem;
  var r: TRect;
  var p: TPoint;
begin
  if ActiveWindowShortcut.Key > 0 then
  begin
    NewState := Word(GetAsyncKeyState(ActiveWindowShortcut.Key)) > 0;
    if NewState <> ActiveWindowShortcut.State then
    begin
      if NewState then OnActiveWindowShortcutDown else OnActiveWindowShortcutUp;
      ActiveWindowShortcut.State := NewState;
    end;
  end;
  if LockShortcut.Key > 0 then
  begin
    NewState := Word(GetAsyncKeyState(LockShortcut.Key)) > 0;
    if NewState <> LockShortcut.State then
    begin
      if NewState then OnLockShortcutDown else OnLockShortcutUp;
      LockShortcut.State := NewState;
    end;
  end;
  if LockState then
  begin
    Window := GetSelectedWindow;
    if Assigned(Window) and IsWindow(Window.Handle) then
    begin
      if not IsIconic(Window.Handle)
      and (GetActiveWindow = Window.Handle) then
      begin
        Windows.GetClientRect(Window.Handle, r);
        p := r.TopLeft;
        Windows.ClientToScreen(Window.Handle, p); r.TopLeft := p;
        p := r.BottomRight;
        Windows.ClientToScreen(Window.Handle, p); r.BottomRight := p;
        if (r.Right - r.Left > 0) and (r.Bottom - r.Top > 0) then
        begin
          ClipCursor(r);
        end;
      end
      else
      begin
        ClipCursor(nil);
      end;
    end
    else
    begin
      ClipCursor(nil);
      LockState := False;
    end;
    Caption := 'Cursor locker (locked)';
  end
  else
  begin
    ClipCursor(nil);
    Caption := 'Cursor locker (unlocked)';
  end;
end;

procedure TForm1.RefreshWidnows;
  var Window: TWindowItem;
  var PrevHandle: HWND;
  var i: Integer;
begin
  Window := GetSelectedWindow;
  if Assigned(Window) then
  begin
    PrevHandle := Window.Handle;
  end
  else
  begin
    PrevHandle := GetForegroundWindow;
  end;
  WindowList.Clear;
  ComboBox1.Clear;
  EnumWindows(@EnumWidnwosCallback, LPARAM(Self));
  WindowList.Sort(@SortWindows);
  ComboBox1.ItemIndex := -1;
  for i := 0 to WindowList.Count - 1 do
  begin
    ComboBox1.Items.Add(WindowList[i].Title);
    if WindowList[i].Handle = PrevHandle then
    begin
      ComboBox1.ItemIndex := i;
    end;
  end;
  if (ComboBox1.ItemIndex = -1)
  and (WindowList.Count > 0) then
  begin
    ComboBox1.ItemIndex := 0;
  end;
end;

function TForm1.GetSelectedWindow: TWindowItem;
begin
  if ComboBox1.ItemIndex > -1 then Exit(WindowList[ComboBox1.ItemIndex])
  else Result := nil;
end;

procedure TForm1.SetLockShortcut(const Key: Word);
  var LSCode: LONG;
  var KeyName: array[0..255] of AnsiChar;
begin
  LSCode := MapVirtualKey(Key, 0);
  if LSCode > 0 then
  begin
    LockShortcut.Key := Key;
    GetKeyNameText(LSCode shl 16, @KeyName, High(KeyName));
    LockShortcut.KeyName := KeyName;
    LockShortcut.State := False;
    Edit1.Text := LockShortcut.KeyName;
  end;
end;

procedure TForm1.SetActiveWindowShortcut(const Key: Word);
  var LSCode: LONG;
  var KeyName: array[0..255] of AnsiChar;
begin
  LSCode := MapVirtualKey(Key, 0);
  if LSCode > 0 then
  begin
    ActiveWindowShortcut.Key := Key;
    GetKeyNameText(LSCode shl 16, @KeyName, High(KeyName));
    ActiveWindowShortcut.KeyName := KeyName;
    ActiveWindowShortcut.State := False;
    Edit2.Text := ActiveWindowShortcut.KeyName;
  end;
end;

procedure TForm1.OnActiveWindowShortcutDown;
  var fw: HWND;
  var i: Integer;
begin
  fw := GetForegroundWindow;
  for i := 0 to WindowList.Count - 1 do
  if WindowList[i].Handle = fw then
  begin
    ComboBox1.ItemIndex := i;
    Break;
  end;
end;

procedure TForm1.OnActiveWindowShortcutUp;
begin

end;

procedure TForm1.OnLockShortcutDown;
begin
  LockState := not LockState;
end;

procedure TForm1.OnLockShortcutUp;
begin

end;

end.

