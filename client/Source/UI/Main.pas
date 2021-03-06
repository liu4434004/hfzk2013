unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, NativeXML, Global, User_Intf, Data_Intf, RVStyle,
  ComCtrls, CustomView, RVScroll, RichView, SNSView,
  SkinTabs, SkinData, DynamicSkinForm,
  spMessages, AppEvnts, ExtCtrls, SkinCtrls, dxGDIPlusClasses, rxAnimate,
  rxGIFCtrl, AccountsView, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, dxNavBar, dxNavBarCollns, cxClasses, dxNavBarBase,
  StdCtrls, SkinGrids, ImgList, rxTimerlst;

type
  TMainForm = class(TForm)
    PageControl: TspSkinPageControl;
    tabLogin: TspSkinTabSheet;
    tabTimeline: TspSkinTabSheet;
    DynamicSkinForm: TspDynamicSkinForm;
    SkinData: TspSkinData;
    CompressedSkinList: TspCompressedSkinList;
    SkinMessage: TspSkinMessage;
    AppEvent: TApplicationEvents;
    LoginSina: TspSkinLinkImage;
    LoginTwitter: TspSkinLinkImage;
    LoginFacebook: TspSkinLinkImage;
    NavBar: TdxNavBar;
    nbgrpAccounts: TdxNavBarGroup;
    nbgrpProCenter: TdxNavBarGroup;
    nbgrpNotify: TdxNavBarGroup;
    nbgrpApps: TdxNavBarGroup;
    nbitemlogin: TdxNavBarItem;
    nbitemmanage: TdxNavBarItem;
    nbitemtimeline: TdxNavBarItem;
    pnlStatus: TspSkinPanel;
    lblAccountName: TspSkinLinkLabel;
    tabManagement: TspSkinTabSheet;
    pgManagement: TspSkinPageControl;
    tabManageSina: TspSkinTabSheet;
    tabManageTwitter: TspSkinTabSheet;
    tabManageFacebook: TspSkinTabSheet;
    lvManageSina: TspSkinListView;
    lvManageTwitter: TspSkinListView;
    lvManageFacebook: TspSkinListView;
    ImageList: TcxImageList;
    tbManagement: TspSkinPanel;
    btnSetCurrent: TspSkinButton;
    btnDeleteAccount: TspSkinButton;
    pnlStatusBar: TspSkinPanel;
    GifStatus: TRxGIFAnimator;
    StatusBar: TspSkinStdLabel;
    lblStatusTips: TspSkinStdLabel;
    btnRefreshAccount: TspSkinButton;
    btnAddAccount: TspSkinButton;
    pnlTimelineRefresh: TspSkinPanel;
    btnTimelineRefresh: TspSkinButton;
    TimerList: TRxTimerList;
    ckbRememberLogin: TspSkinCheckRadioBox;
    tabExtra: TspSkinTabSheet;
    pgExtra: TspSkinPageControl;
    TimelineViewer: TSNSViewer;

    procedure LoginLoading(b: boolean);
    procedure LoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AppEventException(Sender: TObject; E: Exception);
    procedure FormShow(Sender: TObject);
    procedure nbitemloginClick(Sender: TObject);
    procedure nbitemtimelineClick(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure nbitemmanageClick(Sender: TObject);
    procedure lvManageSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnRefreshAccountClick(Sender: TObject);
    procedure btnDeleteAccountClick(Sender: TObject);
    procedure btnAddAccountClick(Sender: TObject);
    procedure btnSetCurrentClick(Sender: TObject);
    procedure lvManageClick(Sender: TObject);
    procedure btnTimelineRefreshClick(Sender: TObject);
    procedure ckbRememberLoginClick(Sender: TObject);
    procedure TimelineViewerSNSLinkClick(Sender: TObject;Category, Extra: String);
    procedure pgExtraAfterClose(Sender: TObject);
  private
    Logined: boolean;

    procedure DoCurrentAccountChange(NewAccount: TAccount);
    function GetAccountFromLV(lv: TListItem): TAccount;
    procedure SetStatus(text: string;b:boolean);
    procedure ChangeTab(tab: TTabSheet);
    procedure UpdateManagement;
    function GetManageLV(Account_Type: TAccount_Type): TspSkinListView;
    procedure DoSelectManagementLV(_type: TAccount_Type);
    procedure SetNB(b: boolean);
    procedure UpdateUserManagement;
    procedure UpdateTimeline;
    procedure Logout;
    procedure Login;
    procedure SetUser(const Msg: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  User: TUser;
  CurrentAccount: TAccount;
  
implementation

uses web_connect, XMLObj, MainHelper, Cache_, ViewerFactory, CustomViewFrame, ShellAPI;

{$R *.dfm}

{ TMainForm }

procedure TMainForm.AppEventException(Sender: TObject; E: Exception);
begin
  if E is Global.EConnectError then
    Warn(Format(Err_Connect,[(E as EConnectError).URL]), MB_OK);
  if E is Global.EAccountExpiredError then
    Warn(Err_Expired, MB_OK);
end;

procedure TMainForm.btnDeleteAccountClick(Sender: TObject);
var
  account: TAccount;
  res: Integer;
begin
  account := self.GetAccountFromLV(TspSkinListView(pgManagement.ActivePage.Controls[0]).Selected);
  res := Warn('确定要删除账户：'+account.Info.screen_name+'？', MB_YESNO);
  case res of
    idYes: begin
             User.DeleteAccount(account);
             Info('删除成功！', MB_OK);
           end;  
    idNo: ;
  end;
end;

procedure TMainForm.btnRefreshAccountClick(Sender: TObject);
begin
  self.UpdateManagement;
end;

procedure TMainForm.btnSetCurrentClick(Sender: TObject);
var
  _type: TAccount_Type;
  i: Integer;
begin
  i := -1;
  for _type := atSina to atFacebook do
    if self.GetManageLV(_type).ItemIndex>=0 then
    begin
      i := self.GetManageLV(_type).ItemIndex;
      break;
    end;
  if i = -1 then
  begin
    Info('请先选中一个账号！',MB_OK);
    exit;
  end;
  CurrentAccount := User.Accounts[_type, self.GetManageLV(_type).ItemIndex];
  self.lblAccountName.Caption := CurrentAccount.Info.screen_name;
end;

procedure TMainForm.btnTimelineRefreshClick(Sender: TObject);
begin
  UpdateTimeline;
end;

procedure TMainForm.ChangeTab(tab: TTabSheet);
begin
  PageControl.ActivePage.TabVisible := False;
  PageControl.ActivePage := tab;
end;

procedure TMainForm.ckbRememberLoginClick(Sender: TObject);
begin
  if not (Sender as TspSkinCheckRadioBox).Checked then
  begin
    SetINIUser('');
    exit;
  end;
  if Assigned(User) then
    SetINIUser(User.ID);
end;

procedure TMainForm.DoCurrentAccountChange(NewAccount: TAccount);
var
  i: Integer;
begin
  CurrentAccount := NewAccount;
  Cache.Account_Type := CurrentAccount.Account_Type;
  Cache.Account_Name := CurrentAccount.Account_Name;
  self.lblAccountName.Caption := CurrentAccount.Info.screen_name;
  for i := pgExtra.PageCount-1 to 0 do
    pgExtra.Pages[i].Free;
  TimelineViewer.ClearAll;
end;

procedure TMainForm.DoSelectManagementLV(_type: TAccount_Type);
var
  accset: set of TAccount_Type;
  ty: TAccount_Type;
begin
  accset := [atSina,atFacebook,atTwitter];
  accset := accset - [_type];
  for ty in accset do
    self.GetManageLV(ty).ItemIndex := -1;
end;

procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if NewWidth < 685 then Resize :=False;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(User) then
    FreeAndNil(User);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Logout;
  TimelineViewer.OnSNSLinkClick := self.TimelineViewerSNSLinkClick;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  id_user: string;
begin
  id_user := Global.GetINIUser;
  if id_user <> '' then
  begin
    User := TUser.Create(id_user);
    Login;
  end;
end;

function TMainForm.GetAccountFromLV(lv: TListItem): TAccount;
var
  tab: TTabSheet;
begin
  tab := lv.ListView.Parent as TTabSheet;
  result := User.Accounts[TAccount_Type(tab.TabIndex), lv.Index];
end;

function TMainForm.GetManageLV(Account_Type: TAccount_Type): TspSkinListView;
var
  tab: TTabSheet;
begin
  tab := pgManagement.Pages[Ord(Account_Type)];
  result := tab.Controls[0] as TspSkinListView;
end;

procedure TMainForm.Login;
begin
  Logined := True;
  CurrentAccount := User.FirstAccount;
  Cache.ID := User.ID;
  Cache.Account_Type := CurrentAccount.Account_Type;
  Cache.Account_Name := CurrentAccount.Account_Name;

  self.lblAccountName.Caption := CurrentAccount.Info.screen_name;
  self.lblStatusTips.Caption := '欢迎你';
  SetNB(True);
  self.UpdateUserManagement;
 // self.UpdateTimeline;
end;

procedure TMainForm.LoginClick(Sender: TObject);
var
  msg: string;
begin
  if GetLoginMsg(TAccount_Type((Sender as TControl).Tag), msg) = mrOK then
    SetUser(Msg);
end;

procedure TMainForm.LoginLoading(b: boolean);
begin
  if b then
    SetStatus('提交数据中……', b)
  else
    SetStatus('', b);
end;

procedure TMainForm.Logout;
begin
  if Assigned(User) then
  begin
    User.Free;
    CurrentAccount := nil;
  end;
  Logined := False;

  lblStatusTips.Caption := '您还未登录';
  self.lblAccountName.Caption := '';
  SetNB(false);
  ChangeTab(tabLogin);
end;

procedure TMainForm.lvManageClick(Sender: TObject);
var
  listview: TspSkinListView;
begin
  listview := Sender as TSpSkinListView;
  self.DoSelectManagementLV(TAccount_Type((listview.Parent as TTabSheet).TabIndex));
end;

procedure TMainForm.lvManageSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  listview: TspskinListview;
  msg: string;
begin
  listview := Item.ListView as TspSkinListView;
  btnDeleteAccount.Enabled := True;

  if User.AccountsCount() = 1 then
    btnDeleteAccount.Enabled := False;
end;

procedure TMainForm.nbitemloginClick(Sender: TObject);
begin
  if not Logined then
    ChangeTab(tabLogin)
  else
  begin
    case Warn('确定要退出登录吗？', MB_YESNO) of
      idYes: Logout;
      idNo: ;
    end;
  end;
end;

procedure TMainForm.nbitemmanageClick(Sender: TObject);
begin
  ChangeTab(tabManagement);
end;

procedure TMainForm.nbitemtimelineClick(Sender: TObject);
begin
  ChangeTab(tabTimeline);
end;

procedure TMainForm.pgExtraAfterClose(Sender: TObject);
begin
  if pgExtra.PageCount<=0 then
    ChangeTab(tabTimeline);
end;

procedure TMainForm.SetNB(b: boolean);
begin
  self.nbgrpProCenter.Visible := b;
  self.nbgrpNotify.Visible := b;
  self.nbgrpApps.Visible := b;
  self.nbitemmanage.Visible := b;
  if b then
    self.nbitemlogin.Caption := '退出登录'
  else
    self.nbitemlogin.Caption := '登录';
end;

procedure TMainForm.SetStatus(text: string;b: boolean);
begin
  StatusBar.Caption := text;
  GifStatus.Animate := b;
  GifStatus.Visible := b;
end;

procedure TMainForm.SetUser(const Msg: string);
const
  strError = '此账号已被其他用户关联，请 切换用户 或者 重新登录账号！';
  strSuccess1 = '登录成功！';
  strSuccess2 = '账户添加成功！';
var
  node: TNode;
  id: string;
begin
  node := parse(Msg);
  id := QueryAccount(string(node['account_type'].Value), node['account_name'].Value);
  if (not Logined) and (id = '') then
  begin
    LoginLoading(True);
    User := CreateUser;
    User.AddAccount(Msg);       
    Info(strSuccess1, MB_OK);
    LoginLoading(False);
    Login;
  end
  else
  if Logined and (id = '') then
  begin
    LoginLoading(True);
    User.AddAccount(Msg);
    Info(strSuccess2, MB_OK);
    LoginLoading(False);
    ChangeTab(tabManagement);
  end
  else
  if (not Logined) and (id <> '') then
  begin
    LoginLoading(True);
    ModifyAccount(node);
    User := TUser.Create(id);
    Info(strSuccess1, MB_OK);
    LoginLoading(False);
    Login;
    ChangeTab(tabManagement);
  end
  else
  begin
    Info(strError, MB_OK);
  end;
  node.Free;
end;

procedure TMainForm.TimelineViewerSNSLinkClick(Sender: TObject; Category,
  Extra: String);
var
  Frame: TCustomViewerFrame;
  tab: TTabSheet;
  Node: TNode;
  Name: string;
  i: integer;
begin
  if Category = 'url' then
  begin
    ShellExecute(handle,nil,
      pchar(Extra),nil,nil,SW_SHOWNORMAL);
    exit;
  end;
  
  Name := Category+'_'+Extra;
  tab := nil;
  for i := 0 to pgExtra.PageCount-1 do
    if pgExtra.Pages[i].Name = Name then
      tab := pgExtra.Pages[i];
  if Assigned(tab) then
  begin
    pgExtra.ActivePage := tab;
    ChangeTab(tabExtra);
    exit;
  end;
  tab := TTabSheet.Create(pgExtra);
  tab.PageControl := pgExtra;
  tab.Name := Category+'_'+Extra;
  tab.Caption := Extra;
  pgExtra.ActivePage := tab;

  ChangeTab(tabExtra);
  if Category = 'mention' then
  begin
    with CurrentAccount.API do
    begin
      Category := 'user';
      AddArg('ID', Extra);
      Node := QuerySmart();
    end;
    Frame := ViewerFactory.CreateViewer(tab, vtUser, Node);
    Frame.SkinFrame.CtrlsSkinData := SkinData;
  end;
end;

procedure TMainForm.btnAddAccountClick(Sender: TObject);
begin
  ChangeTab(tabLogin);
end;

procedure TMainForm.UpdateManagement;
var
  _type: TAccount_Type;
  listview: TspSkinListview;
  i: Integer;
  item: TListItem;
  bmp: TBitmap;
begin
  ImageList.Clear;

  for _type := atSina to atFacebook do
  begin
    listview := self.GetManageLV(_type);
    listview.Clear;
    for i := 0 to User.AccountsCount(_type)-1 do
    begin
      item := listview.Items.Add;
      bmp := GraphicToBmp(
                          GetPictureFromURL(
                          User.Accounts[_type, i].Info.profile_image.Small));
      item.ImageIndex := ImageList.Add(bmp, nil);
      bmp.free;
      item.Caption := User.Accounts[_type, i].Info.screen_name;
    end;
  end;
end;

procedure TMainForm.UpdateTimeline;
begin
  SetStatus('更新时间线……', True);
  MainHelper.UpdatePublicTimeline(self.TimelineViewer);
  SetStatus('更新成功！', False);
end;

procedure TMainForm.UpdateUserManagement;
begin
  SetStatus('更新账户列表……', True);
  UpdateManagement;
  SetStatus('更新成功！', False);
end;

end.
