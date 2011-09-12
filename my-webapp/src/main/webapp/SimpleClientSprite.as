package 
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	
	[SWF(width = '640', height = '480', frameRate = '60', backgroundColor = '0xffffff')]
	public class SimpleClientSprite extends Sprite implements IClientHandler
	{	
		private static var CONN_HOST:String = "127.0.0.1";
		private static var CONN_PORT:int = 4321;
		private var client:SimpleClient;
		private var _txtLog:TextField = new TextField();
		
		private var _diag:Sprite = new Sprite();
		private var _closeButton:Sprite = new Sprite();
		private var _txtHost1:TextField = new TextField();
		private var _txtHost2:TextField = new TextField();
		private var _txtPort1:TextField = new TextField();
		private var _txtPort2:TextField = new TextField();
		
		public function SimpleClientSprite() 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_BORDER;
			initLog();
			initSettings();
			OutputTraceString("Default Settings:");
			OutputTraceString("       CONN_HOST : " + CONN_HOST);
			OutputTraceString("       CONN_PORT : " + CONN_PORT);
			OutputTraceString("Keyboard Settings: ");
			OutputTraceString("       Enter     : Connect");
			OutputTraceString("       Ctrl      : Settings");
			OutputTraceString("start client");
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
		}
			
		private function onKeyDown(e:KeyboardEvent):void 
		{
			switch (e.keyCode)
			{
				case Keyboard.ENTER:
					connect();
					break;
					
				case Keyboard.CONTROL:
					showSettingDiag();
					break;
			}
		}
		
		private function connect():void 
		{
			if (client == null) 
			{
				client = new SimpleClient(this, CONN_HOST, CONN_PORT);
				OutputTraceString("Connecting, host:" + CONN_HOST + ", port:" + CONN_PORT + ", please wait...");
			}
		}
		
		/**
		 * implements IClientHandler
		 */
		public function clientClose() : void 
		{
			OutputTraceString("clientClose");
		}
		
		/**
		 * implements IClientHandler
		 */
		public function clientConnect() : void
		{
			OutputTraceString("clientConnect, host:" + CONN_HOST + ", port:" + CONN_PORT);
			//var data:ByteArray = LoginPack.login(this.myUserName, "password");
			//this.client.sendMsg(data);
			//this.OutputTraceString("packClientLoginMsg(" + this.myUserName + "," + "password" + ")\n\n");
			//this.client.destroy();
		}
		
		/**
		 * implements IClientHandler
		 */
		public function clientReceive(data:ByteArray) : void
		{
			/*
			var info:Object = CommonPack.unpack(data);
			var result:Array;
			if (info != null) 
			{
				var moduleID:uint = info[0];
				var netMsgID:uint = info[1];
				
				trace("clientReceive data.length == " + data.length);				
				switch(moduleID)
				{
				case Constants.MODL_GAMESERVER:
					{
						switch(netMsgID)
						{
						case Constants.NMSG_LOGIN:
							{
								result = LoginPack.unpack(data);
								
								if (result) 
								{
									var sessionID:int = result[2] as int;
									if (result[0] == this.myUserName) //是自己
									{
										this.mySessionID = sessionID;
									}
									
									this.canvasManager.addSession(sessionID, new Point(0, 0));
								}
							}
							break;
						case Constants.NMSG_KEEPALIVE:
							{
								KeepAlivePack.unpack(data);
							}
							break;
						case Constants.NMSG_MOVE:
							{
								MovePack.unpack(data);
							}
							break;
						default:
							trace("[Warning]unknown netMsgID:" + netMsgID);
							break;
						}
					}
					break;
				default:
					trace("[Warning]unknown moduleID:" + moduleID);
					break;
				}
			}
			*/
		}

		/**
		 * implements IClientHandler
		 */
		public function clientDestroy() : void
		{
			this.client = null;
		}
		
		//--------------------------------------
		private function initSettings():void
		{
			_diag.graphics.beginFill(0x00ff00);
			_diag.graphics.drawRect(0, 0, 300, 200);
			_diag.graphics.endFill();
			_diag.x = 300;
			_diag.y = 200;
			addChild(_diag);
			_diag.addEventListener(MouseEvent.MOUSE_DOWN, onDiagMouseDown);
			_diag.addEventListener(MouseEvent.MOUSE_UP, onDiagMouseUp);
			
			_closeButton.graphics.beginFill(0xff0000);
			_closeButton.graphics.drawRect(0, 0, 30, 20);
			_closeButton.graphics.endFill();
			_diag.addChild(_closeButton);
			_closeButton.addEventListener(MouseEvent.CLICK, onCloseButtonClick);
			
			_txtHost1.multiline = false;
			_txtHost1.autoSize = TextFieldAutoSize.LEFT;
			_txtHost1.mouseEnabled = false;
			_txtHost1.x = 10;
			_txtHost1.y = 50;
			_txtHost1.text = "Host:";
			_diag.addChild(_txtHost1);
			
			_txtHost2.multiline = false;
			_txtHost2.mouseEnabled = true;
			_txtHost2.x = 60;
			_txtHost2.y = 50;
			_txtHost2.width = 60;
			_txtHost2.height = 30;
			_txtHost2.border = true;
			_txtHost2.type = TextFieldType.INPUT;
			_diag.addChild(_txtHost2);
			
			_txtPort1.multiline = false;
			_txtPort1.autoSize = TextFieldAutoSize.LEFT;
			_txtPort1.mouseEnabled = false;
			_txtPort1.x = 10;
			_txtPort1.y = 90;
			_txtPort1.text = "Port:";
			_diag.addChild(_txtPort1);
			
			_txtPort2.multiline = false;
			_txtPort2.mouseEnabled = true;
			_txtPort2.x = 60;
			_txtPort2.y = 90;
			_txtPort2.width = 60;
			_txtPort2.height = 30;
			_txtPort2.border = true;
			_txtPort2.type = TextFieldType.INPUT;
			_diag.addChild(_txtPort2);
			
			showSettingDiag();
			//hideSettingDiag();
		}
		
		private function onCloseButtonClick(e:MouseEvent):void 
		{
			hideSettingDiag();
		}
		
		private function onDiagMouseUp(e:MouseEvent):void 
		{
			_diag.stopDrag();
			CONN_HOST = _txtHost2.text;
			CONN_PORT = int(_txtPort2.text);
		}
		
		private function onDiagMouseDown(e:MouseEvent):void 
		{
			_diag.startDrag();
		}
		
		private function showSettingDiag():void
		{
			_diag.visible = true;
			_txtHost2.text = CONN_HOST;
			_txtPort2.text = CONN_PORT.toString(10);
		}
		
		private function hideSettingDiag():void
		{
			_diag.visible = false;
		}
		//--------------------------------------
		private function initLog():void
		{
			//this._txtLog.autoSize = TextFieldAutoSize.LEFT;
			this._txtLog.border = true;
			this._txtLog.width = 640;
			this._txtLog.height = 480;
			this._txtLog.wordWrap = true;
			this.addChild(_txtLog);
		}
		
		public function OutputTraceString(s:String):void
		{
			var str:String = "[" + new Date().toString() + "]" + s;
			this._txtLog.appendText(str + "\n");
			this._txtLog.scrollV = this._txtLog.numLines;
			trace(str);
		}
	}
}






