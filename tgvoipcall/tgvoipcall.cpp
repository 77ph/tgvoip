#define _XOPEN_SOURCE 600
#define TGVOIP_USE_CALLBACK_AUDIO_IO 1
 
#include "libtgvoip/VoIPController.h"
#include "libtgvoip/VoIPServerConfig.h"
#include "libtgvoip/json11.hpp"

#include <iostream>
#include <vector>
#include <string>
#include <unistd.h>

#include <iomanip>
#include <ctime>
#include <fstream>
#include <filesystem>

//#define SLEEP_TIMEOUT 68000000 // 68 sec | 8 sec

#define SLEEP_TIMEOUT_1SEC 1000000 // 1 sec
#define SLEEP_TIMEOUT_3SEC 3000000 // 3 sec
using namespace json11;

FILE * outputFile;
FILE * inputFile;
bool end_of_voice = false;
bool verbose = false;
bool testing = true;

int char2int(char input){
        if(input >= '0' && input <= '9')
                return input - '0';
        if(input >= 'A' && input <= 'F')
                return input - 'A' + 10;
        if(input >= 'a' && input <= 'f')
                return input - 'a' + 10;
        throw std::invalid_argument("Invalid input string");
}

void hex2bin(const char* src, char* target){
        while(*src && src[1]){
                auto c = char2int(*src)*16 + char2int(src[1]);
                *(target++) = c;
                src += 2;
        }
}


std::string buffer_to_hex(const unsigned char* buffer, std::size_t size = 16) {
        const char* hex = "0123456789ABCDEF";
        std::string res(2 * size, '\0');
        for (std::size_t i = 0; i < size; i++) {
                auto c = buffer[i];
                res[2 * i] = hex[c & 15];
                res[2 * i + 1] = hex[c >> 4];
        }
        return res;
}


std::string int16_to_hex(int16_t i) {
        std::stringstream stream;
        stream << std::hex << i;
        std::string result(stream.str());
        return result;
}

void tokenize(std::string const &str, char delim,std::vector<std::string> &out){
        size_t start;
        size_t end = 0;

        while ((start = str.find_first_not_of(delim, end)) != std::string::npos){
                end = str.find(delim, start);
                out.push_back(str.substr(start, end - start));
        }
}


bool is_zero(int16_t *data) {
        bool result = true;
        size_t max_border = 160; // 160 consecutive zeros
        for (size_t i = 0; i < max_border; i++) {
                if (data[i] != 0) {
                        //cerr << "is_zero_debug_non_zero=" << int16_to_hex(data[i]) << " i=" << i << " ";
                        result = false; 
                        break;
                } 
        }
        return result;
}


void recvAudioFrame(int16_t *data, size_t size) {
        bool end_of_receive = false;
        if(end_of_voice == false) {
                end_of_receive = false; // if transmission end_of_receive == false
        } else {
                end_of_receive = is_zero(data); // after transmission
        }
        if(verbose)
                cerr << "call recvAudioFrame=" <<  buffer_to_hex((unsigned char*)&data,size) << " size=" << size << " end_send=" << end_of_voice << endl;

        if ((outputFile != NULL) && (end_of_receive != true)) {
                if(verbose)
                        cerr << "write to file=" << buffer_to_hex((unsigned char*)&data,size) << endl;
                if (fwrite(data, sizeof(int16_t), size, outputFile) != size) {
                        cerr << "error write to file" << endl;
                }
        }
}

void sendAudioFrame(int16_t *data, size_t size) {
        if(verbose)
                cerr << "call sendAudioFrame size=" << size << endl;

        if(end_of_voice) {
                data = NULL;
                size = 0;
                return;
        }

        size_t result = fread(data, sizeof(int16_t), size, inputFile);

        if(verbose) {
                long position=ftell(inputFile);
                cerr << "pos =" << position << endl;
        }

        if (result != size) {
                fclose(inputFile);
                if(verbose)
                        cerr << "call close inputFile" << endl;
                end_of_voice = true;
        }
}


std::string getFileNameNoExtension(std::string filePath, char seperator = '/') {
        std::size_t dotPos = filePath.rfind('.');
        std::size_t sepPos = filePath.rfind(seperator);
        std::size_t fullPos = filePath.size();  
        std::string myfilename;

        if(sepPos != std::string::npos) {
                myfilename = filePath.substr(sepPos + 1,(fullPos-(sepPos+1))-(fullPos-dotPos));
                std::string res = filePath.substr(0,sepPos + 1) + myfilename;
                return res;
        }
        return "";
}

int ogg2raw(std::string filename) {
        int result = 0;
        std::string fullfilename_raw = filename + ".raw";
        std::string fullfilename_pcm = filename + ".pcm";
        std::string fullfilename_ogg = filename + ".ogg";
        std::string fullfilename_opus = filename + ".opus";
        std::string fullfilename_txt = filename + "_in.txt";

        // версия 24.10
        //opusdec --rate 48000 sample05_e181863bce6738bace6841b174713716.ogg s05_e18.pcm
        //opusenc --raw  --framesize 20 --raw-rate 48000 --raw-chan 1 s05_e18.pcm  s05_e18.opus 
        //
        string str_cmd1 = "opusdec --rate 48000 " + fullfilename_ogg + " " + fullfilename_pcm + " > /dev/null 2>&1";
        const char *command1 = str_cmd1.c_str();
        result = system(command1);
        string str_cmd2 = "opusenc --raw  --framesize 20 --raw-rate 48000 --raw-chan 1 " + fullfilename_pcm + " " + fullfilename_opus + " >/dev/null 2>&1";
        const char *command2 = str_cmd2.c_str();
        result = system(command2);
        string str_cmd3 = "opusdec --rate 48000 " + fullfilename_opus + " " + fullfilename_raw + " --save-range " +  fullfilename_txt + " >/dev/null 2>&1";
        const char *command3 = str_cmd3.c_str();
        result = system(command3);
        return result; 
}


int raw2ogg(std::string filename) {
        int result = 0;
        std::string fullfilename_raw = filename + ".raw";
        std::string fullfilename_ogg = filename + ".ogg";
        std::string fullfilename_txt = filename + "_out.txt";
        //opusenc --raw --raw-chan 1 sound_output_B.raw sound_output_B.opus
        string str_cmd = "opusenc --raw  --raw-rate 48000 --raw-chan 1 " + fullfilename_raw + " " + fullfilename_ogg + " --save-range " + fullfilename_txt + " >/dev/null 2>&1";
        const char *command = str_cmd.c_str();
        result = system(command);
        return result; 
}

int clean_ogg2raw(std::string filename) {
        int result = 0;
        std::string fullfilename_raw = filename + ".raw";
        std::string fullfilename_pcm = filename + ".pcm";
        std::string fullfilename_opus = filename + ".opus";
        std::string fullfilename_txt = filename + "_in.txt";

        result = unlink(fullfilename_raw.c_str());
        result = unlink(fullfilename_pcm.c_str());
        result = unlink(fullfilename_opus.c_str());
        if(testing == false)
                result = unlink(fullfilename_txt.c_str());
        return result;
}


int clean_raw2ogg(std::string filename) {
        int result = 0;
        std::string fullfilename_raw = filename + ".raw";
        std::string fullfilename_txt = filename + "_out.txt";
        result = unlink(fullfilename_raw.c_str());
        if(testing == false)
                result = unlink(fullfilename_txt.c_str());
        return result;
}

int main(int argc, char *argv[]) {
        //parsing command line
        int opt;
        char *c_opt = 0;
        char *k_opt = 0;
        char *i_opt = 0;
        char *o_opt = 0;
        char *l_opt = 0;
        char *r_opt = 0;

        char *ref_port = 0;
        char *tag_caller_hex = 0;
        //std::time_t ttt = std::time(nullptr);

        while ((opt = getopt(argc, argv, "k:i:o:c:l:r:")) != -1) {
                switch (opt){
                        case 'k':
                                k_opt = optarg;
                                if(verbose)
                                        cout << "k: " << k_opt << endl;
                                break;
                        case 'i':
                                i_opt = optarg;
                                if(verbose)
                                        cout << "i: " << i_opt << endl;
                                break;
                        case 'o':
                                o_opt = optarg;
                                if(verbose)
                                        cout << "o: " << o_opt << endl;
                                break;
                        case 'c':
                                c_opt = optarg;
                                if(verbose)
                                        cout << "c: " << c_opt << endl;
                                break;
                        case 'l':
                                l_opt = optarg;
                                if(verbose)
                                        cout << "l: " << l_opt << endl;
                                break;
                        case 'r':
                                r_opt = optarg;
                                if(verbose)
                                        cout << "r: " << r_opt << endl;
                                break;
                        default:
                                cerr << "Usage: " << argv[0] << " reflector:port tag_caller_hex -k encryption_key_hex -i /path/to/sound_A.ogg -o /path/to/sound_output_B.ogg -c config.json -l id -r caller|callee\n";
                                return 1;
                }
        }

        if(optind != 13) {
                cerr << "Usage: " << argv[0] << " reflector:port tag_caller_hex -k encryption_key_hex -i /path/to/sound_A.ogg -o /path/to/sound_output_B.ogg -c config.json -l id -r caller|callee\n";
                return 1;
        }

        ref_port = argv[13];
        tag_caller_hex = argv[14];
//      split ipv4:ports 
        std::string s = ref_port;
        const char delim = ':';
        std::vector<std::string> ipv4_port;
        tokenize(s, delim, ipv4_port);

        if(ipv4_port[0].empty() || ipv4_port[1].empty()) {
                cerr << "Usage: " << argv[0] << " reflector:port tag_caller_hex -k encryption_key_hex -i /path/to/sound_A.ogg -o /path/to/sound_output_B.ogg -c config.json -l id -r caller|callee\n";
                return 1;
        } 

        std::string input_file_and_exp = i_opt;
        std::string output_file_and_exp = o_opt;
        std::string converted_input_file_name;
        std::string converted_output_file_name;

        input_file_and_exp = getFileNameNoExtension(input_file_and_exp);
        output_file_and_exp = getFileNameNoExtension(output_file_and_exp);

        if(ogg2raw(input_file_and_exp)) {
                cerr << "internal error." << endl;
                return 1;
        }

        converted_input_file_name = input_file_and_exp + ".raw";
        converted_output_file_name = output_file_and_exp + ".raw";

        inputFile = fopen(converted_input_file_name.c_str(),"r"); 
        if (inputFile == NULL) { 
                cerr << "no such file for read:" << converted_input_file_name.c_str() << endl; 
                return 1; 
        }

        outputFile = fopen(converted_output_file_name.c_str(),"w"); 
        if (outputFile == NULL) { 
                cerr << "no such file for write:" << converted_output_file_name.c_str() << endl; 
                return 1; 
        }


        string line;
        ifstream myfile (c_opt);
        if (myfile.is_open()) {
                while (getline(myfile,line)) {
                }
                myfile.close();
        } else {
                cerr << "no such file for config:" << c_opt << endl;
                return 1;
        }

        std::string json_str = line;
        std::string json_err;
        auto json_config = Json::parse(json_str, json_err);
        if(!json_err.empty()) {
                cerr << "json error:" << json_err << "config:" << json_str << endl;
                return 1; 
        }
        tgvoip::ServerConfig::GetSharedInstance()->Update(json_str);

        //VoIPController Object

        auto ctrl = new tgvoip::VoIPController();
        std::vector<tgvoip::Endpoint> eps;
        tgvoip::IPv4Address v4addr(ipv4_port[0].c_str());
        tgvoip::IPv6Address v6addr("::0");
        char * p_tag_tmp = (char*) calloc (16,sizeof(char));
        unsigned char p_tag[16];
        int64_t p_id = strtoll(l_opt, (char **)NULL, 10);
        uint16_t p_port = strtol(ipv4_port[1].c_str(), (char **)NULL, 10);
        bool tcp = json_config["use_tcp"].bool_value();
        bool allow_p2p = false;
        bool outgoing = false; // true for caller
        uint16_t connection_max_layer = tgvoip::VoIPController::GetConnectionMaxLayer();
        //uint16_t connection_max_layer = 76;

        if(strcmp("caller",r_opt) == 0) {
                outgoing = true;
        }

        char encryptionKey[256];
        hex2bin(k_opt,encryptionKey);
        ctrl->SetEncryptionKey(encryptionKey, outgoing);
        hex2bin(tag_caller_hex,p_tag_tmp);
        memcpy(p_tag, p_tag_tmp, 16);
        free(p_tag_tmp);
        eps.emplace_back(tgvoip::Endpoint(p_id, p_port, v4addr, v6addr, tcp ? tgvoip::Endpoint::Type::TCP_RELAY : tgvoip::Endpoint::Type::UDP_RELAY, p_tag));
        ctrl->SetRemoteEndpoints(eps, allow_p2p, connection_max_layer);        
        ctrl->SetNetworkType(7); // ethernet
        std::cout << ctrl->GetDebugLog() << endl;


        tgvoip::VoIPController::Config config;
        config.enableNS=json_config["use_system_ns"].bool_value();
        //config.enableAEC=json_config["use_system_aec"].bool_value();
        config.enableAEC=false; // Acoustic Echo Cancellation 
        config.enableAGC=json_config["use_ios_vpio_agc"].bool_value();
        config.enableCallUpgrade=false;
        config.initTimeout=5.0; // 5s
        config.recvTimeout=5.0; // 5s
        ctrl->SetConfig(config);

        auto callbacks = tgvoip::VoIPController::Callbacks();
        callbacks.connectionStateChanged = [](
                        tgvoip::VoIPController *controller,
                        int state) {
                        // cerr << "connectionStateChanged=" << state << endl;
        };

        callbacks.signalBarCountChanged = [](
                        tgvoip::VoIPController *controller,
                        int state) {
                        // cerr << "signalBarCountChanged=" << state << endl;
        };

        callbacks.groupCallKeyReceived = nullptr;
        callbacks.groupCallKeySent = nullptr;
        callbacks.upgradeToGroupCallRequested = nullptr;
        ctrl->SetCallbacks(callbacks);

        ctrl->SetAudioDataCallbacks([](int16_t *buffer, size_t size) { sendAudioFrame(buffer, size); }, [](int16_t *buffer, size_t size) { recvAudioFrame(buffer, size); });

        // Processing .. Start->Connect->Stop

        ctrl->Start();
        ctrl->Connect();

        //tgvoipcall устанавливает соединение с собеседником и передаёт весь свой звуковой файл, после чего дождёт 3 секунды для завершения приёма данных от собеседника (длительность звуковых файлов выбирается примерно одинаковая)
        //Если не удалось установить соединение в течение таймаута (5 секунд), приложение выводит ошибку в STDERR и выходит с ненулевым exit code'ом.
        //main cycle
        int16_t counter = 0;
        while(true) {
                if((ctrl->GetConnectionState() == 3) && (end_of_voice == false)) {
                        counter = 0;
                        if(verbose)
                                std::cout << ".";
                }
                if((ctrl->GetConnectionState() == 3) && (end_of_voice == true)) {
                        //после чего дождёт 3 секунды для завершения приёма данных от собеседника 
                        counter = 0;
                        if(verbose)
                                std::cout << "sleep 3 sec after sending ..." << endl;
                        usleep(SLEEP_TIMEOUT_3SEC); // >= size voice file
                        break;
                }
                counter++;
                if(counter >= 5) {
                        fclose(inputFile);
                        fclose(outputFile);
                        break;
                }
                usleep(SLEEP_TIMEOUT_1SEC); // <= size voice file 
        }

        ctrl->Stop();
        if(counter == 0) {
                std::cout << ctrl->GetDebugLog() << endl;
        } else {
                cerr << ctrl->GetDebugLog() << endl;
        }

        // Finish all
        if(raw2ogg(output_file_and_exp)) {
                cerr << "internal error" << endl;
        }
        clean_ogg2raw(input_file_and_exp);
        clean_raw2ogg(output_file_and_exp);

        if(counter)
                return 1;
        return 0;
}
