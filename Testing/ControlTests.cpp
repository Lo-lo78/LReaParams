#include "lrp/MidiControl.h"
#include "lrp/ReaEqChunk.h"
#include "lrp/ReaEqVirtual.h"
#include "lrp/Profile.h"
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
        // ReaEQ negative virtual IDs and non-linear Lua Type enum are stable.
        require(reaeq::enabled(0)==-100000 && reaeq::type(0)==-100001);
        require(reaeq::enabled(2)==-100004 && reaeq::type(2)==-100005);
        require(reaeq::target==-99998 && reaeq::action==-99999);
        for(int i=0;i<11;++i)require(reaeq::userFromRaw(reaeq::rawFromUser(i))==i);
        require(reaeq::rawFromUser(2)==8 && reaeq::userFromRaw(2)==10);
        const auto initial=reaeq::pluginOrder(2,9,compareParamIndex);
        require(initial.size()==16 && initial[0]==-100000 && initial[1]==-100001 &&
            initial[5]==-100002 && initial[6]==-100003 &&
            initial[10]==reaeq::target && initial[11]==reaeq::action &&
            initial[12]==compareParamIndex && initial[13]==6 && initial[15]==8);
        // Extend and remove a real band; footer, magic and the first band must survive.
        std::string chunk(40,'\0');chunk[0]=33;chunk[4]=0;chunk.back()='Z';
        ReaEqChunk noBands(ReaEqChunk::encode(chunk));
        noBands.addBand();require(noBands.bands()==1 && noBands.enabled(0)==1 && noBands.rawType(0)==8);
        auto withOne=ReaEqChunk::decode(noBands.text());
        require(withOne.size()==73 && withOne.substr(0,4)==chunk.substr(0,4) && static_cast<unsigned char>(withOne[4])==1 && withOne.back()=='Z');
        noBands.addBand();require(noBands.bands()==2);
        auto withTwo=ReaEqChunk::decode(noBands.text());
        require(withTwo.substr(8,33)==withOne.substr(8,33));
        noBands.removeBand(1);require(noBands.bands()==1 && ReaEqChunk::decode(noBands.text())==withOne);
        rejected=false;try {noBands.removeBand(0);}catch(...) {rejected=true;}require(rejected);
        std::cout<<"MIDI decode, pickup crossing/jitter/rearm and ReaEQ chunk tests passed\n";return 0;
    }catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}
}
