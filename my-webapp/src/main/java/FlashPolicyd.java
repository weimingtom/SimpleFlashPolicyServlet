import java.io.DataInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.ServerSocket;
import java.net.Socket;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;

/**
 * Servlet implementation class FlashPolicyd
 */
public class FlashPolicyd extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final boolean enableServer1 = true;
    private ServerSocket serverSock;
    private boolean listening = true;
    private Thread serverThread;
    
    private static final boolean enableServer2 = true;
    private ServerSocket serverSock2;
    private boolean listening2 = true;
    private Thread serverThread2;

    /**
     * @see HttpServlet#HttpServlet()
     */
    public FlashPolicyd() {
	super();
	// TODO Auto-generated constructor stub
    }

    /**
     * @see Servlet#init(ServletConfig)
     */
    public void init(ServletConfig config) throws ServletException {
	//see http://windelk.iteye.com/blog/147177
	super.init(config);
	// TODO Auto-generated method stub
	try {
	    String filename = "/WEB-INF/flashpolicy.xml";
	    ServletContext context = getServletContext();
	    final InputStream is = context.getResourceAsStream(filename);
	    final byte policyFileBytes[] = new byte[is.available()];
	    is.read(policyFileBytes);
	    System.out.println("policyFileBytes length = " + policyFileBytes.length);
	    //
	    serverThread = new Thread(new Runnable() {
		public void run() {
		    try {
			System.out.println("PolicyServerServlet: Starting...");
			serverSock = new ServerSocket(843, 50);
			while (listening) {
			    System.out
				    .println("PolicyServerServlet: Listening...");
			    final Socket sock = serverSock.accept();
			    Thread t = new Thread(new Runnable() {
				public void run() {
				    try {
					System.out
						.println("PolicyServerServlet: Handling Request...");
					sock.setSoTimeout(10000);
					InputStream in = sock.getInputStream();
					byte[] buffer = new byte[23];
					if (in.read(buffer) != -1
						&& (new String(buffer))
							.startsWith("<policy-file-request/>")) {
					    System.out
						    .println("PolicyServerServlet: Serving Policy File...");
					    // get the local tomcat path, and
					    // the path to our flashpolicy.xml
					    // file
					    /*
					    File policyFile = new File(
			    			    "/tomcat/policyserver/ROOT/flashpolicy.xml");
					    
					    BufferedReader fin = new BufferedReader(
						    new FileReader(policyFile));
					    */
					    OutputStream out = sock
						    .getOutputStream();
					    /*
					    String line;
					    while ((line = fin.readLine()) != null) {
						out.write(line.getBytes());
					    }
					    */
					    out.write(policyFileBytes);
					    //fin.close();
					    out.write(0x00);
					    out.flush();
					    out.close();
					} else {
					    System.out
						    .println("PolicyServerServlet: Ignoring Invalid Request");
					    System.out.println("  "
						    + (new String(buffer)));
					}
				    } catch (Exception ex) {
					System.out
						.println("PolicyServerServlet: Error: "
							+ ex.toString());
					ex.printStackTrace();
				    } finally {
					try {
					    sock.close();
					} catch (Exception ex2) {
					    ex2.printStackTrace();
					}
				    }
				}
			    });
			    t.start();
			}
		    } catch (Exception ex) {
			System.out.println("PolicyServerServlet: Error: "
				+ ex.toString());
			ex.printStackTrace();
		    }
		}
	    });
	    if(enableServer1)
		serverThread.start();
	} catch (Exception ex) {
	    System.out.println("PolicyServerServlet Error---");
	    ex.printStackTrace(System.out);
	}
	
	//simple echo server, only one connection.
	try {
	    serverThread2 = new Thread(new Runnable() {
		@Override
		public void run() {
			Socket socket; 
			String s; 
			InputStream Is;
			OutputStream Os;
			DataInputStream DIS; 
			PrintStream PS;
			try {
			    serverSock2 = new ServerSocket(4321);
			    listening2 = true;
			} catch (IOException e1) {
			    // TODO Auto-generated catch block
			    e1.printStackTrace();
			}
			while(listening2 && serverSock2 != null) {
			    try {  
				System.out.println("***************** ");
				System.out.println("Port 4321 accept..."); 
				System.out.println("***************** "); 
				socket = serverSock2.accept();
				Is = socket.getInputStream(); 
				Os = socket.getOutputStream();  
				DIS = new DataInputStream(Is); 
				PS = new PrintStream(Os);
				while(true){ 
					System.out.println("please wait client's message..."); 
					s = DIS.readLine(); 
					if(s == null)
					    break;
					System.out.println("client said:" + s);
					PS.println(s);
				} 
			    } catch(Exception e){ 
				System.out.println("Error:"+e); 
			    }
		        }
		}
	    });
	    if(enableServer2)
		serverThread2.start();
	} catch (Exception ex) {
	    System.out.println("PolicyServerServlet Error---");
	    ex.printStackTrace(System.out);
	}
    }

    /**
     * @see Servlet#destroy()
     */
    public void destroy() {
	// TODO Auto-generated method stub
	System.out.println("PolicyServerServlet: Shutting Down...");

	if (listening) {
	    listening = false;
	}
	if (!serverSock.isClosed()) {
	    try {
		serverSock.close();
	    } catch (Exception ex) {
		ex.printStackTrace();
	    }
	}

	
	if (listening2) {
	    listening2 = false;
	}
	if (!serverSock2.isClosed()) {
	    try {
		serverSock2.close();
	    } catch (Exception ex) {
		ex.printStackTrace();
	    }
	}
    }

}
