package vn.edu.stu.dh52201042_parknow_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.stu.dh52201042_parknow_backend.model.Violation;
import java.util.List;

@Repository
public interface ViolationRepository extends JpaRepository<Violation, Long> {
    List<Violation> findByParkingLotId(Long parkingLotId);
    List<Violation> findByStatus(String status);
    List<Violation> findByReportedBy(Long staffId);
    List<Violation> findByParkingLotIdAndStatus(Long parkingLotId, String status);
    List<Violation> findByVehiclePlate(String vehiclePlate);
    List<Violation> findByVehiclePlateIn(List<String> vehiclePlates);
}
