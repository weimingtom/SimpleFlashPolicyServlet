import java.beans.PropertyVetoException;
import java.sql.Connection;
import java.util.TimerTask;
import java.sql.Statement;
import java.sql.ResultSet;

import com.mchange.v2.c3p0.ComboPooledDataSource;

public class XMLServiceTask extends TimerTask {
    private static ComboPooledDataSource pool;
    private final static String SQL_QUERY = "select now();";

    public XMLServiceTask() {
	init();
    }

    /**
     * use c3p0-config.xml or hard-code
     * 
     * @throws PropertyVetoException
     */
    /*
     * public void initC3p0() throws PropertyVetoException {
     * pool.setDriverClass("com.mysql.jdbc.Driver");
     * pool.setJdbcUrl("jdbc:mysql://localhost:3306/test?autoReconnect=true");
     * pool.setUser("root"); pool.setPassword(""); pool.setAcquireIncrement(3);
     * pool.setMaxPoolSize(30); }
     */

    public void init() {
	// see Professional Apache Tomcat 6 (c) by Wrox
	// see http://www.mchange.com/projects/c3p0/index.html
	try {
	    pool = new ComboPooledDataSource();
	    // initC3p0();
	} catch (Exception ex) {
	    ex.printStackTrace();
	}
    }

    @Override
    public void run() {
	// TODO Auto-generated method stub
	Connection conn = null;
	Statement stmt = null;
	ResultSet rset = null;
	try {
	    conn = pool.getConnection();
	    stmt = conn.createStatement();
	    // rset = stmt.executeQuery("select now();");
	    rset = stmt.executeQuery(SQL_QUERY);
	    while (rset.next()) {
		String result = rset.getString(1);
		System.out.println(result.toString());
	    }
	} catch (Throwable ex) {
	    ex.printStackTrace();
	} finally {
	    attemptClose(rset);
	    attemptClose(stmt);
	    attemptClose(conn);
	}
    }

    static void attemptClose(ResultSet o) {
	try {
	    if (o != null)
		o.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

    static void attemptClose(Statement o) {
	try {
	    if (o != null)
		o.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

    static void attemptClose(Connection o) {
	try {
	    if (o != null)
		o.close();
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }
}
