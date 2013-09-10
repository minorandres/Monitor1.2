/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package Modelo;

import CSV.CSVManager;
import java.util.Observable;

/**
 *
 * @author casa
 * esta clase maneja los datos de la conexion para
 * que exista consistencia entre lo que manejan todas las
 * interfaces por eso extiende de observable
 */
public class LogIn extends Observable{
     CSVManager csv=new CSVManager();
     private static LogIn instancia = null;
     String usuario="usuario de la BD";
     String contrasena="contraseña de la BD";
     String puerto="5432";
     String IP="localhost";

    public LogIn(){
        leerCSV();
    }
    public String getUsuario() {
        return usuario;
    }

    public void setUsuario(String usuario) {        
        this.usuario = usuario;
         setChanged();
       notifyObservers();
    }

    public String getContrasena() {
        return contrasena;
    }

    public void setContrasena(String contrasena) {
        this.contrasena = contrasena;
         setChanged();
       notifyObservers();
    }

    public String getPuerto() {
        return puerto;
    }

    public void setPuerto(String puerto) {
        this.puerto = puerto;
         setChanged();
       notifyObservers();
    }

    public String getIP() {
        return IP;
    }

    public void setIP(String IP) {
        this.IP = IP;
         setChanged();
       notifyObservers();
    }
    
    public static LogIn obtenerInstancia() {

      if (instancia == null) {
         instancia = new LogIn();
      }
      return instancia;
   }
    
    public String[] getDatos(){
        String[] datos={this.usuario,this.contrasena,this.puerto,this.IP};
        return datos;
    }
      
  public void leerCSV(){
       String[] valores= csv.lector();
          if(valores!=null){
            this.usuario=valores[0];
            this.contrasena=valores[1];
            this.puerto=valores[2];
            this.IP=valores[3];
          }
  }

    public void escritor(String recordarEstosDatos) {
        csv.escritor(recordarEstosDatos);
    }
    
    public void escribirDatosHistorial(String datos){
        csv.escritorDatosHistoricos(datos);
    }

    public void setValores(String text, String text0, String text1, String text2) {
        usuario=text;
        contrasena=text0;
        puerto=text1;
        IP=text2;
        setChanged();
       notifyObservers();
    }
}
