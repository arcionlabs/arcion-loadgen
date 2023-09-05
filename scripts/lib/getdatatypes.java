///usr/bin/env jbang "$0" "$@" ; exit $? 

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
public class DatabaseMetadata_getTypeInfo {
   public static void main(String args[]) throws SQLException {
      //Registering the Driver
      DriverManager.registerDriver(new com.mysql.jdbc.Driver());
      //Getting the connection
      String url = "jdbc:mysql://localhost/mydatabase";
      Connection con = DriverManager.getConnection(url, "root", "password");
      System.out.println("Connection established......");
      //Retrieving the meta data object
      DatabaseMetaData metaData = con.getMetaData();
      //Retrieving the columns in the database
      ResultSet info = metaData.getTypeInfo();
      //Printing the column name and size
      while (info.next()) {
         System.out.println("Data type name: "+info.getString("TYPE_NAME"));
         System.out.println("Integer value representing this datatype: "+info.getInt("DATA_TYPE"));
         System.out.println("Maximum precision of this datatype: "+info.getInt("PRECISION"));
         if(info.getBoolean("CASE_SENSITIVE")) {
            System.out.println("Current datatype is case sensitive ");
         } else {
            System.out.println("Current datatype is not case sensitive ");
         }
         if(info.getBoolean("AUTO_INCREMENT")) {
            System.out.println("Current datatype can be used for auto increment");
         } else {
            System.out.println("Current datatype can not be used for auto increment");
         }
         System.out.println(" ");
      }
   }
}
