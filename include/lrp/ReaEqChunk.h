#pragma once
#include <string>
#include <vector>
#include <array>
#include <cstdint>
#include <cstring>
#include <cmath>
#include <stdexcept>

namespace lrp {
// Exact Lua ReaEQ layout: 8-byte header, N*33-byte bands, 32-byte footer.
// Never guess a layout when a future plugin returns a different chunk.
class ReaEqChunk {
public:
    static std::string decode(const std::string& text) {
        const std::string alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::string bytes;uint32_t acc=0;int bits=0;
        for(unsigned char c:text) {
            if(c=='=' )break;
            if(c==' '||c=='\r'||c=='\n'||c=='\t')continue;
            auto n=alphabet.find(static_cast<char>(c));
            if(n==std::string::npos)throw std::runtime_error("Invalid ReaEQ base64");
            acc=(acc<<6)|static_cast<uint32_t>(n);bits+=6;
            if(bits>=8){bits-=8;bytes+=static_cast<char>((acc>>bits)&255);}
        }return bytes;
    }
    static std::string encode(const std::string& bytes) {
        const char* alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::string result;
        for(size_t i=0;i<bytes.size();i+=3) {
            const uint32_t a=static_cast<unsigned char>(bytes[i]);
            const uint32_t b=i+1<bytes.size()?static_cast<unsigned char>(bytes[i+1]):0;
            const uint32_t c=i+2<bytes.size()?static_cast<unsigned char>(bytes[i+2]):0;
            const uint32_t v=(a<<16)|(b<<8)|c;
            result+=alphabet[(v>>18)&63];result+=alphabet[(v>>12)&63];
            result+=i+1<bytes.size()?alphabet[(v>>6)&63]:'=';
            result+=i+2<bytes.size()?alphabet[v&63]:'=';
        }return result;
    }
    explicit ReaEqChunk(const std::string& text):bytes_(decode(text)) {
        if(bytes_.size()<40)throw std::runtime_error("Short ReaEQ chunk");
        const auto n=read32(4);
        if(n>64 || bytes_.size()!=40+33*static_cast<size_t>(n))throw std::runtime_error("Unsupported ReaEQ layout");
        count_=static_cast<int>(n);
    }
    int bands() const {return count_;}
    double value(int band,int type) const {
        const size_t pos=offset(band,type);double value=0;std::memcpy(&value,bytes_.data()+pos,8);
        if(!std::isfinite(value))throw std::runtime_error("Non-finite ReaEQ value");return value;
    }
    void value(int band,int type,double value) {
        if(!std::isfinite(value))throw std::runtime_error("Non-finite ReaEQ value");
        const size_t pos=offset(band,type);std::memcpy(bytes_.data()+pos,&value,8);
    }
    // A real band is one opaque 33-byte record; unlike normalized host params,
    // this keeps the untouched bands and footer bit-for-bit identical.
    static std::string defaultBand() {
        static constexpr unsigned char bytes[33]={
            0x01,0x08,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0xE0,
            0x85,0x40,0x00,0x00,0x00,0x00,0x00,0x00,0xF0,0x3F,
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x01,0x00,0x01,0x00};
        return {reinterpret_cast<const char*>(bytes),sizeof(bytes)};
    }
    int enabled(int band) const {
        if(band<0||band>=count_)throw std::runtime_error("Invalid ReaEQ band");
        return static_cast<unsigned char>(bytes_[8+33*static_cast<size_t>(band)])?1:0;
    }
    int rawType(int band) const {
        if(band<0||band>=count_)throw std::runtime_error("Invalid ReaEQ band");
        return static_cast<int>(read32(8+33*static_cast<size_t>(band)+1));
    }
    void addBand(){
        if(count_>=64)throw std::runtime_error("Maximum ReaEQ band count");
        bytes_.insert(8+static_cast<size_t>(count_)*33,defaultBand());
        setBandCount(++count_);
    }
    void removeBand(int zeroBased){
        if(count_<=1||zeroBased<0||zeroBased>=count_)throw std::runtime_error("Cannot remove ReaEQ band");
        bytes_.erase(8+static_cast<size_t>(zeroBased)*33,33);
        setBandCount(--count_);
    }
    std::string text() const {return encode(bytes_);}
private:
    uint32_t read32(size_t pos) const {
        uint32_t value=0;for(int i=0;i<4;++i)value|=static_cast<uint32_t>(static_cast<unsigned char>(bytes_[pos+i]))<<(8*i);return value;
    }
    void setBandCount(int n){for(int i=0;i<4;++i)bytes_[4+static_cast<size_t>(i)]=static_cast<char>((static_cast<uint32_t>(n)>>(8*i))&255);}
    size_t offset(int band,int type) const {
        if(band<0||band>=count_||type<0||type>2)throw std::runtime_error("Invalid ReaEQ band");
        return 8+33*static_cast<size_t>(band)+8+8*static_cast<size_t>(type);
    }
    std::string bytes_;int count_=0;
};
}
