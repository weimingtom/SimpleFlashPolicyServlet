package
{
	import flash.net.Socket;
	import flash.events.SecurityErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	/**
	 * 1. 调用ByteArray的读操作前，必须调用一次ByteArray::bytesAvailable
	 * @author 
	 */
	public class SimpleClient
	{
		private var _socket:Socket;
		private var _host:String;
		private var _port:int;
		private var _handler:IClientHandler;
		private static const SEND_HEAD:String = "CT";
		private static const RECV_HEAD:String = "SR";
		public function SimpleClient(handler:IClientHandler, host:String = "127.0.0.1" , port:int = 1139)
		{
			if (handler == null)
				throw new Error("IClientHandler cannot be null");
				
			this._handler = handler;
			this._host = host;
			this._port = port;
			this._socket = new Socket(this._host, this._port);
			this._socket.addEventListener(Event.CLOSE, onClose);
			this._socket.addEventListener(Event.CONNECT, onConnect);
			this._socket.addEventListener(ProgressEvent.SOCKET_DATA, onData);
			this._socket.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			this._socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			trace("host : " + this._host + " port : " + this._port);
		}
		
		/**
		 * 主动断开
		 */
		public function destroy():void 
		{
			_handler.clientClose();				
			if (this._socket) {	
				this._socket.close();
				this._socket.removeEventListener(Event.CLOSE, onClose);
				this._socket.removeEventListener(Event.CONNECT, onConnect);
				this._socket.removeEventListener(ProgressEvent.SOCKET_DATA, onData);
				this._socket.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
				this._socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				this._socket = null;
				this._handler.clientDestroy();				
			}
		}
		
		/**
		 * 被动断开
		 * @param	event
		 */
		private function onClose(event:Event):void
		{
			_handler.clientClose();	
			if (this._socket)
			{
				this._socket.close();
				this._socket.removeEventListener(Event.CLOSE, onClose);
				this._socket.removeEventListener(Event.CONNECT, onConnect);
				this._socket.removeEventListener(ProgressEvent.SOCKET_DATA, onDataPayLoad);
				this._socket.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
				this._socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				this._socket = null;
				this._handler.clientDestroy();				
			}
		}
		
		private function onConnect(event:Event):void
		{
			_handler.clientConnect();
		}

		/**
		 * 这里可以模拟粘包
		 * @param	data
		 */
		public function sendMsg(data:ByteArray) : void 
		{
			if (this._socket && this._socket.connected)
			{
				this._socket.writeUTFBytes(SEND_HEAD);
				this._socket.writeInt(data.length);
				this._socket.writeBytes(data);
				this._socket.flush();
			}
		}	
		
		private function onDataIdle(event:ProgressEvent):void
		{
			trace("onDataIdle");
		}
		/**
		 * 粘包处理方案：(基于2 byte的长度头定界，readUTF()的二进制版本 )
		 * payload - 有效载荷(darkstar-as3, http://code.google.com/p/darkstar-as3/), 头部回退循环法
		 *           类似的还有L potato 
		 * 			(http://code.google.com/p/lpotato/source/browse/trunk/java/toolkit/WebContent/test/flash/SocketBridge.as?r=13)
		 * hudo - 头部标记isReadHead(sudo, http://code.google.com/p/hudo/), 头部已读递归法
		 * utf - as3有可以根据长度读出utf8字符串的函数，对于文本型协议(如json)可以直接解析
		 * 
		 * 粘包的出现是因为接收tcp是基于事件的，而tcp的数据包是流，事件的响应时间大于包的输入的间隔
		 * 同样，包长度过大也会导致分多次接收的问题（用延迟读解决）
		 */
		// onDataUTF
		// onDataHudo;
		// onDataPayLoad;
		// onDataIdle
		private var onData:Function = onDataHudo;
		
		private var messageBuffer:ByteArray = new ByteArray();
		private function onDataPayLoad(event:ProgressEvent):void
		{
			try {
				/*			
				var bytes:uint = this._socket.bytesAvailable;
				
				if(bytes > 0) {
					var len:uint;//var len:uint = this._socket.readUTF();
					var cmd:String = this._socket.readUTF();
				}
				
				trace("onData bytesAvailable == " + bytes);	
				trace("cmd == " + cmd + " len == " + len);
				*/
				
				trace("SimpleClient.onDataPayLoad(): received [" + event.bytesLoaded + "] bytes");
				var buf:ByteArray = new ByteArray();
				this._socket.readBytes(buf, 0, this._socket.bytesAvailable);
				messageBuffer.writeBytes(buf, 0, buf.length);
				messageBuffer.position = 0;
				while (messageBuffer.bytesAvailable > 2)
				{
					var payloadLength:int = messageBuffer.readShort();

					if (messageBuffer.bytesAvailable >= payloadLength)
					{
						var newMessage:ByteArray = new ByteArray();
						messageBuffer.readBytes(newMessage, 0, payloadLength);
						
						//TODO:在这里取出newMessage即可
						_handler.clientReceive(newMessage);
					}
					else
					{
						//下次再读的时候不会跳过长度字段
						messageBuffer.position -= 2;
						break;
					}
				}
				
				var newBuffer:ByteArray = new ByteArray();
				newBuffer.writeBytes(messageBuffer, messageBuffer.position, messageBuffer.bytesAvailable);
				messageBuffer = newBuffer; //给下次读
				
				//_handler.clientReceive();
				this.destroy();
			} catch (e:Error) {
				//不可以失败
				trace(e.getStackTrace());
			}
		}
		
		//hudo的算法
		//see http://code.google.com/p/hudo/
		private static const headLen:int = 6;//消息头长度
		private var isReadHead:Boolean = true;//是否已经读了消息头
		private var msgcmd:int;
		private var msgLen:int;//消息长度
		private var msgLenMax:int = 4099;//收到的消息最大长度=包头+4K
		private var head1:int = 0;
		private var head2:int = 0;
		private var headFlag:String;
		private function onDataHudo(event:ProgressEvent):void
		{
			trace("SimpleClient.onDataHudo(): received [" + event.bytesLoaded + "] bytes");			
			try {	
				resolvemsg(this._socket.bytesAvailable);
							
				//在resolvemsg里面接收，不是在这里
				//_handler.clientReceive();
				
				//主动关闭TCP(可选)
				//this.destroy();
			} catch (e:Error) {
				//不可以失败
				trace(e.getStackTrace());
			}
		}
		
		/**
		 * 这个函数是递归的，需要单独写出来
		 * @param	intCD
		 */
		private function resolvemsg(intCD:int):void 
		{
			if (isReadHead) 
			{
				if (intCD >= headLen) 
				{
					headFlag = this._socket.readUTFBytes(2);
					if (headFlag == RECV_HEAD) 
					{
						msgLen = this._socket.readInt();//读长度
						isReadHead = false;
						intCD -= headLen;
					}
					else
					{
						trace("unknown package head");
						
						//清空读缓冲
						this._socket.readBytes(new ByteArray(), 0, _socket.bytesAvailable);
						isReadHead = true;
						intCD = 0;
					}
				}
			}
			
			if (!isReadHead) 
			{
				if (intCD >= msgLen) 
				{
					var newMessage:ByteArray = new ByteArray();	
					this._socket.readBytes(newMessage, 0, msgLen);				
					//trace("msgLen == " + msgLen);
					
					//TODO:在这里取出newMessage即可
					_handler.clientReceive(newMessage);
					
					isReadHead = true;
					intCD = intCD - msgLen;
				}
			}
			
			//多合一包用递归来解析
			if (intCD >= headLen)
			{
				trace("拈包处理:" + intCD);
				resolvemsg(intCD);
			}
		}
		
		//readUTF算法, 不适合pack结构的包		
		private static const HEADER_LENGTH:int = 2;
		private function onDataUTF(event:ProgressEvent):void
		{
			trace("SimpleClient.onDataUTF(): received [" + event.bytesLoaded + "] bytes");			
			try {
				//循环，防止粘包
				while(this._socket.bytesAvailable >= HEADER_LENGTH) 
				{
					var messageLength:int = this._socket.readShort();
					var messageBody:String = "";
					trace("messageLength:" + messageLength);
					if (this._socket.bytesAvailable >= messageLength)
					{
						messageBody = this._socket.readUTFBytes(messageLength);
						
						trace("messageBody:" + messageBody);
						
						//如果可以，直接传String给clientReceive更方便，这里做了ByteArray转换						
						var newMessage:ByteArray = new ByteArray();	
						newMessage.writeUTFBytes(messageBody);
						
						//TODO:在这里取出newMessage即可
						_handler.clientReceive(newMessage);
					}
				}
				
				//主动关闭TCP(可选)
				this.destroy();
			} catch (e:Error) {
				//不可以失败
				trace(e.getStackTrace());
			}
		}
		
		private function onIoError(event:IOErrorEvent):void 
		{
			trace("onIoError");	
			this.destroy();	
		}
		
		private function onSecurityError(event:SecurityErrorEvent):void 
		{
			trace("onSecurityError");
			this.destroy();
		}
		
		public static function printHex(data:ByteArray):void 
		{
			var str:String = ""; 
			for (var i:int = 0; i < data.length; i++)
			{
				str += data[i] + ",";
			}
			trace("printHex():" + str);
		}
	}
}
