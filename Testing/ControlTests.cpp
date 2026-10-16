#include "lrp/MidiControl.h"
#include "lrp/ReaEqChunk.h"
#include <iostream>
#include <stdexcept>
using namespace lrp;
void require(bool ok) {if(!ok)throw std::runtime_error("Control test failed");}
int main() {
    try {
        unsigned char valid[]={0xb2,74,127}, note[]={0x92,74,127}, bad[]={0xb0,128,0};
        auto cc=decodeCc(valid,3);require(cc&&cc->channel==3&&cc->number==74&&cc->value==127);
        require(!decodeCc(note,3)&&!decodeCc(bad,3)&&!decodeCc(valid,2));
        Pickup pickup;
        require(!pickup.allows(0,0.7));require(!pickup.allows(60,0.7));require(pickup.allows(100,0.7));
        pickup.applied(100/127.0);
        require(!pickup.allows(101,100/127.0));require(!pickup.allows(101,100/127.0));require(pickup.allows(101,100/127.0));
        pickup.applied(101/127.0);
        require(!pickup.allows(110,0.2)); // external edit rearms takeover
        require(pickup.allows(10,0.2)); // crossing target
        pickup.applied(10/127.0);pickup.reset();require(!pickup.allows(127,0));
        require(pickup.allows(0,0)); // endpoint tolerance
        // Opaque header/footer and untouched bands must survive exact byte roundtrip.
        for(int count:{0,1,4,64}) {
            std::string bytes(40+33*count,'\0');bytes[0]=33;bytes[4]=static_cast<char>(count);
            bytes.back()='X';
            auto encoded=ReaEqChunk::encode(bytes);require(ReaEqChunk::decode(encoded)==bytes);
            ReaEqChunk model(encoded);require(model.bands()==count&&model.text()==encoded);
            if(count) {
                model.value(count-1,1,63.8);require(std::abs(model.value(count-1,1)-63.8)<1e-12);
                auto changed=ReaEqChunk::decode(model.text());
                size_t start=8+33*(count-1)+16;
                require(changed.substr(0,start)==bytes.substr(0,start));
                require(changed.substr(start+8)==bytes.substr(start+8));
            }
        }
        bool rejected=false;try {ReaEqChunk invalid("AAAA");}catch(...) {rejected=true;}require(rejected);
        std::cout<<"MIDI decode, pickup crossing/jitter/rearm and ReaEQ chunk tests passed\n";return 0;
    }catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}
}
