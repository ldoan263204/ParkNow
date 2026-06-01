package vn.edu.stu.dh52201042_parknow_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.stu.dh52201042_parknow_backend.model.Shift;
import java.util.List;
import java.util.Optional;

@Repository
public interface ShiftRepository extends JpaRepository<Shift, Long> {
    List<Shift> findByStaffId(Long staffId);
    List<Shift> findByParkingLotId(Long parkingLotId);
    Optional<Shift> findByStaffIdAndStatus(Long staffId, String status);
    List<Shift> findByStaffIdOrderByStartTimeDesc(Long staffId);
}
