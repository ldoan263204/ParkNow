import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class FixDb {
    public static void main(String[] args) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        String url = "jdbc:mysql://parknow-cloud-ldoan263204-c1be.f.aivencloud.com:23446/defaultdb?useSSL=true&requireSSL=true";
        String user = "avnadmin";
        String password = "AVNS_1Frl0Fq11EgSIcZB9Bh";
        
        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            stmt.executeUpdate("ALTER TABLE users DROP COLUMN password_hash;");
            System.out.println("Dropped password_hash column successfully.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
