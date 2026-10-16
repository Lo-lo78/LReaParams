#include "lrp/MidiControl.h"
#include "lrp/ReaEqChunk.h"
#include "lrp/ReaEqVirtual.h"
#include "lrp/DynamicsSpecial.h"
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
        // ReaEQ reports an unreliable setter boolean on some hosts. A
        // successful readback must not be announced as an update failure.
        require(reaeq::bandWriteAcceptedOrVerified(false,"1",1));
        require(reaeq::bandWriteAcceptedOrVerified(false,"08",8));
        require(reaeq::bandWriteAcceptedOrVerified(true,"",8));
        require(!reaeq::bandWriteAcceptedOrVerified(true,"0",1)); // setter accepted, but readable state contradicts it
        require(!reaeq::bandWriteAcceptedOrVerified(false,"0",1));
        require(!reaeq::bandWriteAcceptedOrVerified(false,"",1));
        require(!reaeq::bandWriteAcceptedOrVerified(false,"1junk",1));
        const auto initial=reaeq::pluginOrder(2,9,compareParamIndex);
        require(initial.size()==16 && initial[0]==-100000 && initial[1]==-100001 &&
            initial[5]==-100002 && initial[6]==-100003 &&
            initial[10]==reaeq::target && initial[11]==reaeq::action &&
            initial[12]==compareParamIndex && initial[13]==6 && initial[15]==8);
        // A Lua-era Custom Order has only physical IDs and Compare. The new
        // virtual controls must be adjacent to their respective bands instead
        // of being appended after Global Gain; other physical edits survive.
        const std::vector<int> legacy{0,1,2,4,3,5,compareParamIndex,6,7,8};
        const std::vector<int> expected{reaeq::enabled(0),reaeq::type(0),0,1,2,
            reaeq::enabled(1),reaeq::type(1),4,3,5,reaeq::target,reaeq::action,
            compareParamIndex,6,7,8};
        const auto upgraded=reaeq::mergeLegacyCustomOrder(legacy,2,9,compareParamIndex);
        require(upgraded==expected);
        require(reaeq::mergeLegacyCustomOrder(upgraded,2,9,compareParamIndex)==expected); // idempotent
        // The 0.0.43 code may have written all missing virtuals at the end.
        auto oldAppended=legacy;
        oldAppended.insert(oldAppended.end(),{
            reaeq::enabled(0),reaeq::type(0),reaeq::enabled(1),reaeq::type(1),
            reaeq::target,reaeq::action});
        require(reaeq::mergeLegacyCustomOrder(oldAppended,2,9,compareParamIndex)==expected);
        // An intentionally repositioned virtual in Custom Order is retained.
        auto deliberate=upgraded;
        deliberate.erase(deliberate.begin());
        deliberate.insert(deliberate.begin()+5,reaeq::enabled(0));
        require(reaeq::mergeLegacyCustomOrder(deliberate,2,9,compareParamIndex)==deliberate);
        // Each band can be reordered physically; the new virtuals remain
        // before whichever real parameter of that band appears first.
        const std::vector<int> customPhys{5,3,4,2,0,1,6};
        auto merged=reaeq::mergeLegacyCustomOrder(customPhys,2,7,compareParamIndex);
        require(merged[0]==reaeq::enabled(1) && merged[1]==reaeq::type(1) && merged[2]==5);
        require(merged[5]==reaeq::enabled(0) && merged[6]==reaeq::type(0) && merged[7]==2);
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
        // ReaComp/ReaGate pure adapter fixtures. Compiled only in GitHub Actions.
        using namespace dynamics;
        require(compRange==-200000 && gateRange==-210000 && compRange!=gateRange);
        require(detectorChoices.size()==8);
        for(int i=0;i<8;++i){
            const auto raw=detectorChoices[static_cast<size_t>(i)].raw;
            require(detectorIndex(raw)==i);
            require(detectorRawFromFraction(i/7.0)==raw);
            require(detectorLabel(raw)==detectorChoices[static_cast<size_t>(i)].label);
        }
        // VST SignIn sometimes reports [0,1], mapping raw 0..1084 to host
        // fractions; every Lua enum must still decode to its real label.
        for(int i=0;i<8;++i) {
            const int raw=detectorChoices[static_cast<size_t>(i)].raw;
            const double norm=detectorHostFraction(raw);
            require(detectorHostIndex(norm,0.0,1.0,norm)==i);
            require(detectorHostIndex(raw,0.0,1084.0,norm)==i);
            require(detectorHostIndex(raw,0.0,2048.0,norm)==i);
            require(std::abs(norm-raw/1084.0)<1e-10);
        }
        require(detectorHostIndex(0.5,0.0,1.0,0.5)==-1);
        require(detectorHostIndex(500,0.0,1084.0,500.0/1084.0)==-1);
        require(detectorLabel(123)=="Main inputs");
        require(alias(Kind::comp,"signin")=="Detector input");
        require(alias(Kind::gate,"pre-open")=="Lookahead");
        require(alias(Kind::comp,"pre-comp")=="Lookahead");
        require(toggle(Kind::gate,"invert gate") && toggle(Kind::comp,"auto release"));
        require(!toggle(Kind::comp,"threshold") && !toggle(Kind::gate,"threshold"));
        require(rms("0.0")=="0 ms, peak detector");
        require(rms("15.000 ms")=="15 ms");
        require(filterRange(0,20000)=="Full range");
        require(filterRange(100,20000)=="Above 100 Hz");
        require(filterRange(0,10000)=="Below 10000 Hz");
        require(filterRange(100,10000)=="100 Hz to 10000 Hz");
        const std::vector<std::string> compRaw{"Threshold","Ratio","Attack","Release","Pre-comp",
          "RMS size","Knee","SignIn","Hipass","Lowpass","Filter Preview","Dry","Wet",
          "Auto Make Up Gain","Auto Release","Advanced"};
        const auto compOrder=pluginOrder(Kind::comp,compRaw,compareParamIndex);
        require(compOrder.size()==compRaw.size()+2);
        for(int i=0;i<10;++i)require(compOrder[static_cast<size_t>(i)]==i);
        require(compOrder[10]==compRange && compOrder[11]==10);
        require(compOrder[compOrder.size()-1]==15);
        const std::vector<std::string> gateRaw{"Threshold","Attack","Hold","Release",
          "Hysteresis","Pre-open","RMS size","SignIn","Hipass","Lowpass",
          "Filter Preview","Dry","Wet","Invert Gate","Send MIDI on open/close",
          "MIDI note","MIDI channel","MIDI velocity","AudIn"};
        const auto gateOrder=pluginOrder(Kind::gate,gateRaw,compareParamIndex);
        require(gateOrder[10]==gateRange && gateOrder[11]==10);
        require(gateOrder.size()==gateRaw.size()+2);
        // Retain every physical control exactly once and Compare exactly once.
        for(const auto& row:{compOrder,gateOrder}) {
            int compare=0,virtuals=0;
            for(int id:row){if(id==compareParamIndex)++compare;
                if(id==compRange||id==gateRange)++virtuals;}
            require(compare==1&&virtuals==1);
        }
        std::cout<<"MIDI decode, pickup crossing/jitter/rearm and ReaEQ chunk tests passed\n";return 0;
    }catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}
}
