/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package BD;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JOptionPane;

/**
 *
 * @author casa
 */
public class ConectorSQL {
    
     Connection conexion = null;
     Statement stmt = null;

    public ConectorSQL() {
    }
     
     public boolean conectar(String usuario,String contrasena,String puerto,String ip) {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");

        } catch (ClassNotFoundException e) { 
            JOptionPane.showMessageDialog(null, "No se encontro el Driver JDBC de PostgreSQL", "Error", JOptionPane.ERROR_MESSAGE);
            e.printStackTrace();
            return false;
        }
        conexion = null;
        try {
            conexion = DriverManager.getConnection(
                    "jdbc:oracle:thin:@//"+ip+":"+puerto+"/"+"XE",usuario,
                    contrasena);
            // "jdbc:oracle:thin:@//localhost:1521/XE", "system", "root");
        } catch (SQLException e) {
            JOptionPane.showMessageDialog(null, "Fallo la conexion, revise los datos", "Error", JOptionPane.ERROR_MESSAGE);
            return false;
        }

        if (conexion == null) {
            JOptionPane.showMessageDialog(null, "Fallo la conexion, revise los datos", "Error", JOptionPane.ERROR_MESSAGE);
            return false;
        } else{            
            System.out.println("Conexion BD exitosa");//getTableSpaces();
        }
        getInfoTableSpaces();
        getObjetosEnTableSpace("ACADEMICO");// parametro es el nombre dl ts
        return true;
    }

     public String getInfoTablaRegistro(){
         String query = "SELECT tabla,tablespace,fecha,total_registros,"
                 + "tamanio_total_mb,nuevos_registros FROM REGISTROS "
                 + "ORDER BY TABLA,FECHA ASC";   
          try {
            stmt = conexion.createStatement();
              try (ResultSet resultados = stmt.executeQuery(query)) {
                  query="";
                 while ( resultados.next() ) {                  
                    String  tabla = resultados.getString("TABLA");  System.out.println("Esta es la tabla: "+tabla);
                    String  tablespace = resultados.getString("TABLESPACE");
                    String  fecha = resultados.getString("FECHA");
                    String  total_registros = resultados.getString("TOTAL_REGISTROS");
                    String  tamanio_total_mb = resultados.getString("TAMANIO_TOTAL_MB");
                    String  nuevos_registros = resultados.getString("NUEVOS_REGISTROS");
                    System.out.println(tabla+","+tablespace+","+fecha+","+total_registros+","+
                            tamanio_total_mb+","+nuevos_registros);
                    query+=tabla+","+tablespace+","+fecha+","+total_registros+","+
                            tamanio_total_mb+","+nuevos_registros+"\n";
                 }
             }
             stmt.close();
         } catch (SQLException ex) {
             Logger.getLogger(ConectorSQL.class.getName()).log(Level.SEVERE, null, ex);
         }        
         return query;
     }
     
     public String getObjetosEnTableSpace(String tableSpace){
         String query= "SELECT SEGMENT_NAME, (SUM(BYTES)/1024/1024) TAM"+
                        " FROM DBA_EXTENTS"+
                        " WHERE TABLESPACE_NAME = '"+tableSpace+"'"+
                        " GROUP BY SEGMENT_NAME";
         try {
            stmt = conexion.createStatement();
              try (ResultSet resultados = stmt.executeQuery(query)) {
                 while ( resultados.next() ) {
                    String  segmento = resultados.getString("SEGMENT_NAME");
                    String tam= resultados.getString("TAM");
                    System.out.println(segmento+","+tam);
                    query+=segmento+","+tam+"\n";
                 }
             }
             stmt.close();
         } catch (SQLException ex) {
             Logger.getLogger(ConectorSQL.class.getName()).log(Level.SEVERE, null, ex);
         }         
             return query;  
     }
     
         /*
      * devuelve info de todos los ts
      * en el formato:
      * tablespace,usado,libre,total,%libre
      */
     
     public String getInfoTableSpaces(){ 
         String datos="";       
         try {
            stmt = conexion.createStatement();
             String s="SELECT datafile.tablespace_name "+
                "\"TableSpace\""+
                ",usado "+
                "\"usado\""+
		",(datafile.total - t.usado) "+
                "\"libre\""+
                " ,datafile.total "+ 
                "\"total\""+
                " ,(100*((datafile.total - t.usado)/datafile.total)) " + 
                "\"% libre\""+ 
		" FROM (SELECT tablespace_name,(SUM(bytes)/1048576) total"+
                " FROM dba_data_files GROUP BY tablespace_name) datafile,"+
		"(SELECT (SUM(bytes)/(1048576)) usado,tablespace_name"+
		" FROM dba_segments GROUP BY tablespace_name) t"+
		" WHERE datafile.tablespace_name=t.tablespace_name"    ;
             try (ResultSet resultados = stmt.executeQuery(s)) {
                 while ( resultados.next() ) {
                    String  tablespace = resultados.getString("TableSpace");
                    String usado= resultados.getString("usado");
                    String libre= resultados.getString("libre");
                    String total= resultados.getString("total");
                    String plibre= resultados.getString("% libre");
                    System.out.println(tablespace+","+usado+","+libre+","+total+","+plibre);
                    datos+=tablespace+","+usado+","+libre+","+total+","+plibre+"\n";
                 }
             }
             stmt.close();
         } catch (SQLException ex) {
             Logger.getLogger(ConectorSQL.class.getName()).log(Level.SEVERE, null, ex);
         }         
             return datos;     
     }   
}
