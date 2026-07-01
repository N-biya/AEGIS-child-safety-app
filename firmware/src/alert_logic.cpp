#include "alert_logic.h"

#include <iomanip>
#include <sstream>

namespace aegis {

std::string formatAlertSms(const std::string& statusLabel, const GpsFix& fix,
                            const std::string& timestampIso) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(6);
    out << "[AEGIS Alert]\n";
    out << "Status: " << statusLabel << "\n";
    out << "Location: " << fix.lat << ", " << fix.lng << "\n";
    out << "Time: " << timestampIso;
    return out.str();
}

std::string formatAlertFirestorePayload(const std::string& type,
                                         const VitalsSnapshot& vitals,
                                         const GpsFix& fix,
                                         const std::string& timestampIso,
                                         bool resolved) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(6);
    out << "{"
        << "\"type\":\"" << type << "\","
        << "\"timestamp\":\"" << timestampIso << "\","
        << "\"vitals\":{\"hr\":" << vitals.hr << ",\"spo2\":" << vitals.spo2
        << ",\"gsr\":" << vitals.gsr << ",\"temp\":" << vitals.temp << "},"
        << "\"location\":{\"lat\":" << fix.lat << ",\"lng\":" << fix.lng << "},"
        << "\"resolved\":" << (resolved ? "true" : "false")
        << "}";
    return out.str();
}

void raiseAlert(ISmsSender& sms, IAlertPublisher& alertPublisher,
                 const std::string& childId, const std::string& parentPhone,
                 const std::string& type, const std::string& smsStatusLabel,
                 const VitalsSnapshot& vitals, const GpsFix& fix,
                 const std::string& timestampIso) {
    sms.send(parentPhone, formatAlertSms(smsStatusLabel, fix, timestampIso));
    alertPublisher.publish(childId,
                            formatAlertFirestorePayload(type, vitals, fix, timestampIso));
}

} // namespace aegis
