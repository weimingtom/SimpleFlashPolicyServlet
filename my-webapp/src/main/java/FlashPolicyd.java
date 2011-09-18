import java.io.DataInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.sql.Timestamp;
import java.util.Date;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;

/**
 * Servlet implementation class FlashPolicyd
 */
public class FlashPolicyd extends HttpServlet {
    private static final long serialVersionUID = 1L;

    /**
     * NOTE: Opening www.youku.com video in Chrome will connect 843 port !!!
     */
    private static final boolean enableServer1 = true;
    private ServerSocket serverSock;
    private boolean listening = true;
    private Thread serverThread;

    private static final boolean enableServer2 = true;
    private ServerSocket serverSock2;
    private boolean listening2 = true;
    private Thread serverThread2;

    private static final boolean enableServer3 = true;
    private ServerSocket serverSock3;
    private boolean listening3 = true;
    private Thread serverThread3;
    
    private static String savepath = "C:\\";
    
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
    @Override
    public void init(ServletConfig config) throws ServletException {
	// see http://windelk.iteye.com/blog/147177
	super.init(config);
	// TODO Auto-generated method stub
	try {
	    String filename = "/WEB-INF/flashpolicy.xml";
	    ServletContext context = getServletContext();
	    System.out.println(getTimeString() + 
		    " : Flash policy file is " + filename);
	    System.out.println(getTimeString() + 
		    " : Binary upload files save path is " + savepath);
	    final InputStream is = context.getResourceAsStream(filename);
	    final byte policyFileBytes[] = new byte[is.available()];
	    is.read(policyFileBytes);
	    // System.out.println("policyFileBytes length = "
	    // + policyFileBytes.length);
	    //
	    
	    serverThread = new Thread(new Runnable() {
		public void run() {
		    try {
			// System.out.println("PolicyServerServlet: Starting...");
			serverSock = new ServerSocket(843, 50);
			while (listening && !serverSock.isClosed()) {
			    System.out.println(getTimeString() + " : "
				    + "Flash policy server is listening on "
				    + serverSock.getLocalPort());
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
					     * File policyFile = new File(
					     * "/tomcat/policyserver/ROOT/flashpolicy.xml"
					     * );
					     * 
					     * BufferedReader fin = new
					     * BufferedReader( new
					     * FileReader(policyFile));
					     */
					    OutputStream out = sock
						    .getOutputStream();
					    /*
					     * String line; while ((line =
					     * fin.readLine()) != null) {
					     * out.write(line.getBytes()); }
					     */
					    out.write(policyFileBytes);
					    // fin.close();
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
					// ex.printStackTrace();
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
			// ex.printStackTrace();

		    }
		}
	    });
	    if (enableServer1)
		serverThread.start();
	} catch (Exception ex) {
	    System.out.println("PolicyServerServlet Error---");
	    ex.printStackTrace(System.out);
	}

	// simple echo server, only one connection.
	try {
	    serverThread2 = new Thread(new Runnable() {
		@Override
		public void run() {
		    Socket socket = null;
		    String s;
		    InputStream Is = null;
		    OutputStream Os = null;
		    DataInputStream DIS = null;
		    PrintStream PS = null;
		    try {
			serverSock2 = new ServerSocket(4321);
			listening2 = true;
		    } catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		    }
		    while (listening2 && serverSock2 != null) {
			try {
			    System.out.println(getTimeString() + " : "
				    + "Echo server is listening on "
				    + serverSock2.getLocalPort());
			    socket = serverSock2.accept();
			    Is = socket.getInputStream();
			    Os = socket.getOutputStream();
			    DIS = new DataInputStream(Is);
			    PS = new PrintStream(Os);
			    while (listening2 && serverSock2 != null) {
				System.out
					.println("please wait client's message...");
				s = DIS.readLine();
				if (s == null)
				    break;
				System.out.println("client said:" + s);
				PS.println(s);
			    }
			} catch (Exception e) {
			    // System.out.println("Error:" + e);
			    // e.printStackTrace();

			} finally {
			    if (Is != null) {
				try {
				    Is.close();
				} catch (IOException e) {
				    e.printStackTrace();
				}
			    }
			    if (PS != null) {
				PS.close();
			    }
			    if (Os != null) {
				try {
				    Os.close();
				} catch (IOException e) {
				    e.printStackTrace();
				}
			    }
			    if (socket != null) {
				try {
				    socket.close();
				} catch (IOException e) {
				    e.printStackTrace();
				}
			    }
			}
		    }
		}
	    });
	    if (enableServer2)
		serverThread2.start();
	} catch (Exception ex) {
	    System.out.println("PolicyServerServlet Error---");
	    ex.printStackTrace(System.out);
	}

	// simple upload binary server
	try {
	    serverThread3 = new Thread(new Runnable() {
		@Override
		public void run() {
		    // ServerSocket server = null;
		    try {
			serverSock3 = new ServerSocket(4322);
		    } catch (IOException e) {
			e.printStackTrace();
		    }
		    if (serverSock3 != null) {
			System.out.println(getTimeString() + " : "
				+ "Binary upload server is listening on "
				+ serverSock3.getLocalPort());
			while (listening3 && serverSock3 != null) {
			    Socket sock = null;
			    InputStream input = null;
			    // FileWriter output = null;
			    File file = null;
			    FileOutputStream output = null;
			    try {
				sock = serverSock3.accept();
				input = sock.getInputStream();
				// output = new
				// FileWriter(getFileNameString() +
				// ".txt");
				file = new File(getFileNameString() + ".txt");
				output = new FileOutputStream(file);
				while (listening3 && serverSock3 != null) {
				    int b = input.read();
				    if (b != -1) {
					//System.out.println("read:" + b);
					output.write(b);
					output.flush();
				    } else {
					// EOS
					break;
				    }
				}
			    } catch (IOException e) {
				//e.printStackTrace();
			    } finally {
				try {
				    if (output != null)
					output.close();
				    if (input != null)
					input.close();
				    if (sock != null)
					sock.close();
				} catch (IOException e) {
				    e.printStackTrace();
				}
			    }
			}
		    }
		}
	    });
	    if (enableServer3)
		serverThread3.start();
	} catch (Exception ex) {
	    System.out.println("PolicyServerServlet Error---");
	    ex.printStackTrace(System.out);
	}
    }

    /**
     * @see Servlet#destroy()
     */
    @Override
    public void destroy() {
	// TODO Auto-generated method stub
	System.out.println(getTimeString() + 
		" : Servlet is shutting down...");
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

	if (listening3) {
	    listening3 = false;
	}
	if (!serverSock3.isClosed()) {
	    try {
		serverSock3.close();
	    } catch (Exception ex) {
		ex.printStackTrace();
	    }
	}
    }

    private static String getTimeString() {
	return new Timestamp((new Date()).getTime()).toString();
    }
    
    private static String getFileNameString() {
	return savepath + getTimeString().replace(" ", "_").replace(":", "").replace(".",
		"_");
    }
}
