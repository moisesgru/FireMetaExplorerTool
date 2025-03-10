unit uFireMetaWebModule;

interface

uses
  System.SysUtils,
  System.Classes,
  Web.HTTPApp,
  MVCFramework, FireDAC.Phys.FBDef, FireDAC.Stan.Intf, FireDAC.Phys,
  FireDAC.Phys.IBBase, FireDAC.Phys.FB, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client;

type
  TFireMetaWebModule = class(TWebModule)
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    FMVC: TMVCEngine;
  public
    { Declara��es p�blicas }
  end;

var
  WebModuleClass: TComponentClass = TFireMetaWebModule;

implementation

{$R *.dfm}

uses
  uFireMetaController,

  System.IOUtils,
  MVCFramework.Commons,
  MVCFramework.Middleware.ActiveRecord,
  MVCFramework.Middleware.StaticFiles,
  MVCFramework.Middleware.Analytics,
  MVCFramework.Middleware.Trace,
  MVCFramework.Middleware.CORS,
  MVCFramework.Middleware.ETag,
  MVCFramework.Middleware.Compression;

procedure TFireMetaWebModule.WebModuleCreate(Sender: TObject);
begin
  FMVC := TMVCEngine.Create(Self,
    procedure(Config: TMVCConfig)
    begin
      Config.dotEnv := dotEnv;

      // tempo de sess�o (0 significa cookie de sess�o)
      Config[TMVCConfigKey.SessionTimeout] := dotEnv.Env('dmvc.session_timeout', '0');

      // tipo de conte�do padr�o 'application/json'
      Config[TMVCConfigKey.DefaultContentType] := dotEnv.Env('dmvc.default.content_type', TMVCConstants.DEFAULT_CONTENT_TYPE);

      // charset de conte�do padr�o 'UTF-8'
      Config[TMVCConfigKey.DefaultContentCharset] := dotEnv.Env('dmvc.default.content_charset', TMVCConstants.DEFAULT_CONTENT_CHARSET);

      // a��es n�o tratadas s�o permitidas?
      Config[TMVCConfigKey.AllowUnhandledAction] := dotEnv.Env('dmvc.allow_unhandled_actions', 'false');

      // habilitar ou n�o o carregamento dos controladores do sistema (dispon�vel apenas para requisi��es de localhost)
      Config[TMVCConfigKey.LoadSystemControllers] := dotEnv.Env('dmvc.load_system_controllers', 'true');

      // extens�o de arquivo de visualiza��o padr�o
      Config[TMVCConfigKey.DefaultViewFileExtension] := dotEnv.Env('dmvc.default.view_file_extension', 'html');

      // caminho da visualiza��o
      Config[TMVCConfigKey.ViewPath] := dotEnv.Env('dmvc.view_path', 'templates');

      // usar cache para visualiza��es do lado do servidor (use "false" no debug e "true" em produ��o para melhor desempenho)
      Config[TMVCConfigKey.ViewCache] := dotEnv.Env('dmvc.view_cache', 'false');

      // contagem m�xima de registros para CRUD autom�tico de entidades
      Config[TMVCConfigKey.MaxEntitiesRecordCount] := dotEnv.Env('dmvc.max_entities_record_count', IntToStr(TMVCConstants.MAX_RECORD_COUNT));

      // habilitar assinatura do servidor na resposta
      Config[TMVCConfigKey.ExposeServerSignature] := dotEnv.Env('dmvc.expose_server_signature', 'false');

      // habilitar cabe�alho X-Powered-By na resposta
      Config[TMVCConfigKey.ExposeXPoweredBy] := dotEnv.Env('dmvc.expose_x_powered_by', 'true');

      // tamanho m�ximo da requisi��o em bytes
      Config[TMVCConfigKey.MaxRequestSize] := dotEnv.Env('dmvc.max_request_size', IntToStr(TMVCConstants.DEFAULT_MAX_REQUEST_SIZE));

    end);

  FMVC.AddController(TFireMetaController);

  // Middleware de an�lise gera um log CSV, �til para fazer an�lise de tr�fego
  //FMVC.AddMiddleware(TMVCAnalyticsMiddleware.Create(GetAnalyticsDefaultLogger));

  // A pasta mapeada como documentroot para o TMVCStaticFilesMiddleware deve existir!
  //FMVC.AddMiddleware(TMVCStaticFilesMiddleware.Create('/static', TPath.Combine(ExtractFilePath(GetModuleName(HInstance)), 'www')));

  // Middleware de rastreamento produz um log mais detalhado para fins de depura��o
  FMVC.AddMiddleware(TMVCTraceMiddleware.Create);

  // Middleware CORS lida com... bem, CORS
  //FMVC.AddMiddleware(TMVCCORSMiddleware.Create);

  // Simplifica a defini��o de conex�o do TMVCActiveRecord
  FMVC.AddMiddleware(TMVCActiveRecordMiddleware.Create(
    dotEnv.Env('firedac.connection_definition_name', 'MyConnDef'),
    dotEnv.Env('firedac.connection_definitions_filename', ExtractFilePath(ParamStr(0)) + 'FDConnectionDefs.ini')
  ));

  // Middleware de compress�o deve ser o �ltimo na cadeia, logo antes do ETag, se presente.
  FMVC.AddMiddleware(TMVCCompressionMiddleware.Create);

  // Middleware ETag deve ser o �ltimo na cadeia
  FMVC.AddMiddleware(TMVCETagMiddleware.Create);


  {
  FMVC.OnWebContextCreate(
    procedure(const Context: TWebContext)
    begin
      // Inicializa servi�os para torn�-los acess�veis a partir do Contexto
      // Context.CustomIntfObject := TMyService.Create;
    end);

  FMVC.OnWebContextDestroy(
    procedure(const Context: TWebContext)
    begin
      // Limpeza de servi�os, se necess�rio
    end);
  }
end;

procedure TFireMetaWebModule.WebModuleDestroy(Sender: TObject);
begin
  FMVC.Free;
end;

end.

