#ifndef CHECK_RESULT_STREAM_HANDLER_H_
#define CHECK_RESULT_STREAM_HANDLER_H_

#include <flutter/event_channel.h>
#include <flutter/encodable_value.h>

#include <mutex>
#include <memory>

namespace xpoint_sdk {

class CheckResultStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
public:
    CheckResultStreamHandler() = default;
    virtual ~CheckResultStreamHandler() = default;

    void SendEvent(const flutter::EncodableValue& data) {
        std::lock_guard<std::mutex> lock(sink_mutex_);
        if (sink_) {
            sink_->Success(data);
        }
    }

protected:
    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
        const flutter::EncodableValue* arguments,
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override {
        std::lock_guard<std::mutex> lock(sink_mutex_);
        sink_ = std::move(events);
        return nullptr;
    }

    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
        const flutter::EncodableValue* arguments) override {
        std::lock_guard<std::mutex> lock(sink_mutex_);
        sink_.reset();
        return nullptr;
    }

private:
    std::mutex sink_mutex_;
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

}  // namespace xpoint_sdk

#endif  // CHECK_RESULT_STREAM_HANDLER_H_
