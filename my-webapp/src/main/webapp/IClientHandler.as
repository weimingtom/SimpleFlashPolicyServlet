package 
{
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author 
	 */
	public interface IClientHandler 
	{
		//这些函数都不可以做复杂操作，会导致网络事件阻塞
		function clientClose() : void;
		function clientConnect() : void;
		function clientReceive(buf:ByteArray) : void;
		function clientDestroy() : void;
	}	
}
