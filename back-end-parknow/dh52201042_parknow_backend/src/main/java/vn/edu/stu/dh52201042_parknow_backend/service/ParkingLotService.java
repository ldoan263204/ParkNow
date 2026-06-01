package vn.edu.stu.dh52201042_parknow_backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.edu.stu.dh52201042_parknow_backend.model.ParkingLot;
import vn.edu.stu.dh52201042_parknow_backend.repository.ParkingLotRepository;
import java.util.List;
import java.util.Optional;

@Service
public class ParkingLotService {

    @Autowired
    private ParkingLotRepository parkingLotRepository;

    public List<ParkingLot> getAllParkingLots() {
        return parkingLotRepository.findAll();
    }

    public List<ParkingLot> getApprovedParkingLots() {
        return parkingLotRepository.findByStatus("approved");
    }

    public List<ParkingLot> getParkingLotsByStatus(String status) {
        return parkingLotRepository.findByStatus(status);
    }

    public Optional<ParkingLot> getParkingLotById(Long id) {
        return parkingLotRepository.findById(id);
    }

    public ParkingLot createParkingLot(ParkingLot parkingLot) {
        if (parkingLot.getStatus() == null) {
            parkingLot.setStatus("pending");
        }
        if (parkingLot.getAvailableSlots() == null && parkingLot.getTotalSlots() != null) {
            parkingLot.setAvailableSlots(parkingLot.getTotalSlots());
        }
        return parkingLotRepository.save(parkingLot);
    }

    public ParkingLot updateParkingLot(Long id, ParkingLot updatedLot) {
        return parkingLotRepository.findById(id).map(lot -> {
            if (updatedLot.getName() != null) lot.setName(updatedLot.getName());
            if (updatedLot.getAddress() != null) lot.setAddress(updatedLot.getAddress());
            if (updatedLot.getLatitude() != null) lot.setLatitude(updatedLot.getLatitude());
            if (updatedLot.getLongitude() != null) lot.setLongitude(updatedLot.getLongitude());
            if (updatedLot.getTotalSlots() != null) lot.setTotalSlots(updatedLot.getTotalSlots());
            if (updatedLot.getAvailableSlots() != null) lot.setAvailableSlots(updatedLot.getAvailableSlots());
            if (updatedLot.getPricePerHour() != null) lot.setPricePerHour(updatedLot.getPricePerHour());
            return parkingLotRepository.save(lot);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy bãi đỗ xe với ID: " + id));
    }

    // Admin phê duyệt bãi đỗ xe
    public ParkingLot approveParkingLot(Long id) {
        return parkingLotRepository.findById(id).map(lot -> {
            lot.setStatus("approved");
            lot.setRejectionReason(null);
            return parkingLotRepository.save(lot);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy bãi đỗ xe với ID: " + id));
    }

    // Admin từ chối bãi đỗ xe
    public ParkingLot rejectParkingLot(Long id, String reason) {
        return parkingLotRepository.findById(id).map(lot -> {
            lot.setStatus("rejected");
            lot.setRejectionReason(reason);
            return parkingLotRepository.save(lot);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy bãi đỗ xe với ID: " + id));
    }

    public void deleteParkingLot(Long id) {
        parkingLotRepository.deleteById(id);
    }
}
