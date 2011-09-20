import java.util.Timer;
import java.util.TimerTask;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;

/**
 * Servlet implementation class XMLServiceServlet
 */
public class XMLServiceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private TimerTask task = null;
    private Timer timer = null;
    private long period = 1000;

    /**
     * @see HttpServlet#HttpServlet()
     */
    public XMLServiceServlet() {
	super();
	// TODO Auto-generated constructor stub
    }

    @Override
    public void init() throws ServletException {
	// TODO Auto-generated method stub
	// super.init();
	start();
    }

    @Override
    public void destroy() {
	// TODO Auto-generated method stub
	if (timer != null) {
	    timer.cancel();
	    timer = null;
	}
	super.destroy();
	System.out.println("XMLServiceServlet destroy");
    }

    private void start() {
	if (task == null) {
	    task = new XMLServiceTask();
	}
	timer = new Timer(true);
	timer.schedule(task, 0, period);
	System.out.println("XMLServiceServlet start.");
    }
}
