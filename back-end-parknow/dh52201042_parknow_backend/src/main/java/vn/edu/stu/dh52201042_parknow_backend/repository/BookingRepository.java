package vn.edu.stu.dh52201042_parknow_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.stu.dh52201042_parknow_backend.model.Booking;
import java.util.List;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {
    List<Booking> findByUserId(Long userId);
    List<Booking> findByParkingLotId(Long parkingLotId);
    List<Booking> findByStatus(String status);
    List<Booking> findByUserIdAndStatus(Long userId, String status);
    List<Booking> findByParkingLotIdAndStatusIn(Long parkingLotId, List<String> statuses);
    boolean existsByParkingLotIdAndSlotNumberAndStatusIn(Long parkingLotId, String slotNumber, List<String> statuses);
}
