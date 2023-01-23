import java.sql.Driver;
import java.sql.DriverManager;
import java.util.Enumeration;
public class DriversList_DriverManager {
   public static void main(String args[])throws Exception {
      //Registering MySQL driver
      DriverManager.registerDriver(new com.mysql.jdbc.Driver());
      //Registering SQLite driver
      DriverManager.registerDriver(new org.sqlite.JDBC());
      //Registering Oracle driver
      DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
      //Registering Derby-client driver
      DriverManager.registerDriver(new org.apache.derby.jdbc.ClientDriver());
      //Registering Derby-autoloaded driver
      DriverManager.registerDriver(new org.apache.derby.jdbc.AutoloadedDriver());
      //Registering HSQLDb-JDBC driver
      DriverManager.registerDriver(new org.hsqldb.jdbc.JDBCDriver());
      System.out.println("List of all the Drivers registered with the DriverManager:");
      //Retrieving the list of all the Drivers
      Enumeration<Driver> e = DriverManager.getDrivers();
      //Printing the list
      while(e.hasMoreElements()) {
         System.out.println(e.nextElement().getClass());
      }
      System.out.println();
   }
}