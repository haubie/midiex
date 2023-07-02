#![allow(unused)]
// #![feature(drain_filter)]
extern crate midir;

#[macro_use]
extern crate lazy_static;

// CORE MIDI TEST
use coremidi::{Destinations, Endpoint, Sources};

use std::sync::{Arc, Mutex};
use std::sync::RwLock; // Potentially use this instead of Mutex for MidiInput and MidiOutput
use std::result::Result;

use core::cell::RefCell;

use std::collections::VecDeque;
// use std::collections::HashSet;
use std::iter::FromIterator;

use std::hash::{Hash, Hasher};

use std::ops::{Deref, DerefMut};
use std::sync::mpsc;

// PLAY TEST
// use std::thread;
use std::thread::sleep;
use rustler::thread;
use std::time::Duration;
use std::io::{stdin, stdout, Write};
use std::ops::Add;


// Send messages to Erlang PID
// use tokio::sync::mpsc::{channel, Receiver, Sender};

use midir::{MidiInput, MidiOutput, MidiInputConnection, MidiOutputConnection, MidiInputPort, MidiOutputPort, Ignore, InitError};

use midir::os::unix::{VirtualInput, VirtualOutput};

use rustler::{Atom, Env, Error, NifResult, NifStruct, NifMap, NifTuple, ResourceArc, Term, Binary, OwnedBinary, OwnedEnv};
use rustler::Encoder;


// IS THIS NEEDED ANYMORE?
// This version uses threadlocal to create the MidiInput and MidiOutput objects
thread_local!(static GLOBAL_MIDI_INPUT_RESULT: Result<MidiInput, InitError> = MidiInput::new("MIDIex"));
thread_local!(static GLOBAL_MIDI_OUTPUT_RESULT: Result<MidiOutput, InitError> = MidiOutput::new("MIDIex"));



// REMOVE: GLOBAL_MIDI_BINARY_MESSAGES - SHOULD NOT BE USED
lazy_static!{
    static ref GLOBAL_MIDI_BINARY_MESSAGES: Mutex<Vec<OwnedBinary>> = Mutex::new(Vec::<OwnedBinary>::new());
}

// GLOBALS FOR INPUT PORTS BEING SUBSCRIBED TO
lazy_static!{
    static ref GLOBAL_LISTEN_LIST: Mutex<Vec<MidiPort>> = Mutex::new(Vec::<MidiPort>::new());
}

// GLOBALS FOR VIRTUAL INPUTS
lazy_static!{
    static ref GLOBAL_VIRTUAL_LISTEN_LIST: Mutex<Vec<VirtualMidiPort>> = Mutex::new(Vec::<VirtualMidiPort>::new());
}
lazy_static!{
    static ref GLOBAL_VIRTUAL_INPUT_COUNTER: Mutex<usize> = Mutex::new(0);
}




// Atoms
mod atoms {
    rustler::atoms! {
        ok,
        error,

        input,
        output,

        message
    }
}





// Send message to Erlang
// Refactor to spin off a thread which listens to input events and sends them to an Erlang process.
// The rust side will need to keep a list of input connections being listened too. Ideally these will be identified by a key (string?)
// There will also need to be a function to close and remove an input connection from the list.
// REFERNCE: Look at this project to see how they did it: https://github.com/rrx/rust-synth/blob/b632bdd915979ad6d8e7973b5362dfdb9853fcb2/src/midi.rs
// RUSTLER REFERENCE: https://github.com/rusterlium/rustler/blob/d8aa66d976fa5ebbc6f74662992448a79a7d2fbf/rustler_tests/native/rustler_test/src/test_env.rs

// fn check_msg_callback<T>(microsecond: u64, message: &[u8], _: &mut T) {

//     let mut owned_env = GLOBAL_OWNED_ENV.lock().unwrap();

//     match *GLOBAL_RETURN_PID.lock().unwrap() {
//         Some(pid) => {
//             owned_env.send_and_clear(&pid, |env| {

//                 let mut the_message = Term::map_new(env);
//                 let mut s = format!("You received this message from Rust.");
//                 // the_message = the_message.map_put("port_name", midi_port.name).unwrap();
//                 // the_message = the_message.map_put("port_num", midi_port.num).unwrap();
//                 the_message = the_message.map_put("message", message).unwrap();
        
//                 the_message
            
//             });
//         },
//         None => println!("No pid"),
//     }

   

//     // println!("Midi message is {:?}", message);
    
// }





#[rustler::nif]
fn unsubscribe_all_ports(env: Env) -> Result<Vec<MidiPort>, Error> {
    // *GLOBAL_LISTEN_LIST.lock().unwrap() = Vec::new();
    GLOBAL_LISTEN_LIST.lock().unwrap().clear();
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec())
}

// #[rustler::nif]
// fn unsubscribe_all_ports(env: Env) -> Result<Vec<usize>, Error> {
//     GLOBAL_LISTEN_LIST_INDEX.lock().unwrap().clear();
//     Ok(GLOBAL_LISTEN_LIST_INDEX.lock().unwrap().to_vec())
// }

#[rustler::nif]
fn unsubscribe_port(env: Env, midi_port: MidiPort) -> Result<Vec<MidiPort>, Error> {
    GLOBAL_LISTEN_LIST.lock().unwrap().retain(|x| *x != midi_port);
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn unsubscribe_port_by_index(env: Env, port_num: usize) -> Result<Vec<MidiPort>, Error> {  
    GLOBAL_LISTEN_LIST.lock().unwrap().retain(|x| x.num != port_num);
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn get_subscribed_ports(env: Env) -> Result<Vec<MidiPort>, Error> {
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec()) 
}

#[rustler::nif]
pub fn subscribe(env: Env, midi_port: MidiPort) -> Atom {    
    // Add the whole port struct to a listeners Vec
    GLOBAL_LISTEN_LIST.lock().unwrap().push(midi_port.clone());
    GLOBAL_LISTEN_LIST.lock().unwrap().sort_unstable_by_key(|midi_port| (midi_port.num));
    GLOBAL_LISTEN_LIST.lock().unwrap().dedup();

    let pid = env.pid();
    
    let mut owned_env = OwnedEnv::new();

    std::thread::spawn(move || {

        let mut midi_in = MidiInput::new("MIDIex input").expect("Midi input");
        midi_in.ignore(Ignore::None);

        let mut in_port = match &midi_port.port_ref.0 {
            MidiexMidiPortRef::Input(in_port) => in_port,
            MidiexMidiPortRef::Output(out_port) => panic!("Midi Input Port Error: Problem getting midi input port reference.")
        };

        let _conn_in = midi_in
            .connect(
                &in_port,
                "midir-read-input",
                move |_stamp, message, _| {
                    owned_env.send_and_clear(&pid, |the_env| { message.encode(the_env) });
                    ()
                },
                (),
            )
            .unwrap();

        let mut still_listen = true;
        while still_listen {
            let mut still_listen = GLOBAL_LISTEN_LIST.lock().unwrap().contains(&midi_port);
        }

    });

    atoms::ok()
}



#[rustler::nif]
fn close_out_conn(midi_out_conn: OutConn) -> Atom {
    midi_out_conn.conn_ref.0
    .lock()
    .expect("lock should not be poisoned")
    .take()
    .expect("there should be a connection")
    .close();

    atoms::ok()
}


// THIS ISN'T NEEDED ANYMORE - fn subscribe/1 is used instead.
#[rustler::nif(schedule="DirtyIo")]
fn listen(env: Env, midi_port: MidiPort) -> Result<Vec<Binary>, Error> {

    let mut midi_msg = Arc::new(Mutex::new(Vec::new()));

    if midi_port.direction == atoms::input()  {

        let mut midi_msg = midi_msg.clone();

        if let MidiexMidiPortRef::Input(in_port) = &midi_port.port_ref.0 { 
        
            let mut midi_input = MidiInput::new("MIDIex").expect("Midi input"); 

            let port_name = midi_input.port_name(in_port).unwrap();

            // _conn_in needs to be a named parameter, because it needs to be kept alive until the end of the scope
            let _conn_in = midi_input.connect(
                &in_port,
                "MIDIex input port",
                move |stamp, message, _| {

                let mut midi_msg_clone = midi_msg.clone();
                let mut vec_msg =  message.to_vec();

                let mut bin_msg: OwnedBinary = OwnedBinary::new(message.len()).expect("Owned binary message created");
                bin_msg.as_mut_slice().copy_from_slice(&vec_msg);

                midi_msg_clone.lock().unwrap().push(bin_msg);
                                
            }, ());   
    
            sleep(Duration::from_millis(5));
          
        };

    } else {
        // println!("\nCannot listen to an output port - use the Midiex.open/1 function instead");
        return Err(Error::RaiseTerm(Box::new(
            "Cannot listen to an output port - use the Midiex.open/1 function instead".to_string(),
        ))) 
    }

    let mut midi_msg_lock =  midi_msg.lock().unwrap();
    let new_vec_of_bin_msgs: Vec<Binary> = (midi_msg_lock
                                        .drain(..)
                                        .map(|owned_bin_msg| owned_bin_msg.release(env))
                                        .collect::<Vec<Binary>>()).to_vec();

    Ok(new_vec_of_bin_msgs)

}



#[rustler::nif]
fn create_virtual_input(env: Env,  port_name: String) -> Result<VirtualMidiPort, Error> {

    let port_index = GLOBAL_VIRTUAL_INPUT_COUNTER.lock().unwrap().add(1);
    Ok(
        VirtualMidiPort{
                        direction: atoms::input(),
                        name: port_name.clone(),
                        num: port_index 
                    }
    )
}

#[rustler::nif]
fn unsubscribe_virtual_port(env: Env, virtual_midi_port: VirtualMidiPort) -> Result<Vec<VirtualMidiPort>, Error> {  
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().retain(|virt_port| virt_port != &virtual_midi_port);
    Ok(GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn unsubscribe_all_virtual_ports(env: Env) -> Result<Vec<VirtualMidiPort>, Error> {
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().clear();
    Ok(GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn get_subscribed_virtual_ports(env: Env) -> Result<Vec<VirtualMidiPort>, Error> {
    Ok(GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().to_vec()) 
}

// This replaces all other create_virtual_input stuff
#[rustler::nif]
pub fn subscribe_virtual_input(env: Env, virtual_midi_port: VirtualMidiPort) -> Atom {    
    // Add the whole port struct to a listeners Vec
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().push(virtual_midi_port.clone());
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().sort_unstable_by_key(|midi_port| (midi_port.num));
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().dedup();

    let pid = env.pid();
    
    let mut owned_env = OwnedEnv::new();

    std::thread::spawn(move || {

        let mut midi_in = MidiInput::new("MIDIex input").expect("Midi input");
        midi_in.ignore(Ignore::None);

        let _conn_in = midi_in
            .create_virtual(
                &virtual_midi_port.name,
                move |_stamp, message, _| {
                    owned_env.send_and_clear(&pid, |the_env| { message.encode(the_env) });
                    ()
                },
                (),
            )
            .unwrap();

        let mut still_listen = true;
        while still_listen {
            let mut still_listen = GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().contains(&virtual_midi_port);
        }

    });

    atoms::ok()
}




#[rustler::nif]
fn connect(midi_port: MidiPort) -> Result<OutConn, Error>{

    if midi_port.direction == atoms::output()  {
        // println!("OUTPUT");

        let mut midi_output = MidiOutput::new("MIDIex").expect("Midi output");  

        // let mut port_ref = midi_port.port_ref.0;

        if let MidiexMidiPortRef::Output(port) = &midi_port.port_ref.0 { 

            // println!("OUTPUT PORT");

            let mut conn_out_result = midi_output.connect(&port, "MIDIex");

            let mut conn_out = match conn_out_result {
                Ok(conn_out) => {
                    // println!("CONNECTION MADE");
                    
                    return Ok(
                        OutConn {
                            conn_ref: ResourceArc::new(OutConnRef::new(conn_out)),
                            // midi_port: midi_port,   
                            name: midi_port.name,
                            port_num: midi_port.num,
                        }
                    )

                },
                Err(error) => panic!("Midi Output Connection Error: Problem getting midi output connection. Error: {:?}", error)
            };
    
            

         };


    } else {
        // println!("INPUT");

        let mut midi_input = MidiInput::new("MIDIex").expect("Midi output");  

        // let mut port_ref = midi_port.port_ref.0;

        if let MidiexMidiPortRef::Input(port) = &midi_port.port_ref.0 { 

            // println!("INPUT PORT");

            // let mut conn_in_result = midi_input.connect(&port, "MIDIex");

            // let mut conn_in = match conn_in_result {
            //     Ok(conn_in) => { println!("CONNECTION MADE"); conn_in},
            //     Err(error) => panic!("Midi Input Connection Error: Problem getting midi input connection. Error: {:?}", error)
            // };

            return Err(Error::RaiseTerm(Box::new(
                "Input connection rather than output.".to_string(),
            )))
    
            

         };
    }



    Err(Error::RaiseTerm(Box::new(
        "No output connection".to_string(),
    )))
}



#[rustler::nif]
fn create_virtual_output_conn(name: String) -> Result<OutConn, Error>{

    let mut midi_output = MidiOutput::new("MIDIex").expect("Midi output");
    let mut midi_input = MidiInput::new("MIDIex").expect("Midi input");
    midi_input.ignore(Ignore::None);

    let mut conn_out = midi_output.create_virtual(&name).expect("Midi MidiOutputConnection");

    // Even though we've created an output port, beacause it's a virtual port it is listed as an 'input' when querying the OS for available devices. 
    let port_index = midi_input.port_count();

    // Just in case added port_ref back into OutConn
    // let new_port: MidiInputPort = midi_input.ports().into_iter().rev().next().unwrap();

    return Ok(
        OutConn {
            conn_ref: ResourceArc::new(OutConnRef::new(conn_out)),
            name: name,
            port_num: port_index-1,

            // Just in case port_ref is added back in:
            // midi_port: MidiPort{
            //     direction: atoms::output(),
            //     name: name,
            //     num: port_index,
            //     port_ref: ResourceArc::new(FlexiPort::new(MidiexMidiPortRef::Output(MidiOutputPort::clone(&new_port)))) 
            // }   
        }
    )

}


#[rustler::nif(schedule = "DirtyCpu")]
fn send_msg(midi_out_conn: OutConn, message: Binary) -> Result<OutConn, Error>{

    let mut midi_output = MidiOutput::new("MIDIex").expect("Midi output"); 

    { 
        let mut binding = midi_out_conn.conn_ref.0.lock().unwrap();
        let out_conn = binding.deref_mut();

        match out_conn {
            Some(conn) => conn.send(&message),
            None => return Err(Error::RaiseTerm(Box::new(
                "No output connection available to send message to. Connection may have been closed.".to_string(),
            ))),
        };
    }
    
    Ok(midi_out_conn)
}


// ===============
// MIDI Connection
// ===============


#[derive(NifStruct)]
#[module = "Midiex.OutConn"]
pub struct OutConn {
    conn_ref: ResourceArc<OutConnRef>,
    // midi_port: MidiPort,
    name: String,
    port_num: usize,
}

// WRAP IN AN OPTION AS WELL SO THE CONN CAN BE DESTROYED LATER
// Use of Option mean ownership of the connection can be taken with .take() and then .closed() can be called.

pub struct OutConnRef(pub Mutex<Option<MidiOutputConnection>>);

impl OutConnRef {
    pub fn new(data: MidiOutputConnection) -> Self {
        Self(Mutex::new(Some(data)))
    }
}


// #[derive(NifStruct, Clone)]
// #[module = "Midiex.InConn"]
// pub struct InConn {
//     conn_ref: ResourceArc<InConnRef>,
//     // midi_port: MidiPort,
//     name: String,
//     port_num: usize,
// }

// WRAP IN AN OPTION AS WELL SO THE CONN CAN BE DESTROYED LATER
// Use of Option mean ownership of the connection can be taken with .take() and then .closed() can be called.

// pub struct InConnRef(pub Mutex<Option<MidiInputConnection<()>>>);

// impl InConnRef {
//     pub fn new(data: MidiInputConnection<()>) -> Self {
//         Self(Mutex::new(Some(data)))
//     }
// }



// ==========
// MIDI Ports
// ==========
pub enum MidiexMidiPortRef {
    Input(MidiInputPort), 
    Output(MidiOutputPort), 
  }

pub struct FlexiPort(pub MidiexMidiPortRef);

impl FlexiPort {
    pub fn new(data: MidiexMidiPortRef) -> Self {
        Self(data)
    }
}

#[derive(NifStruct, Clone)]
#[module = "Midiex.MidiPort"]
pub struct MidiPort {
    direction: Atom,
    name: String,
    num: usize,
    port_ref: ResourceArc<FlexiPort>,
}

impl PartialEq for MidiPort {
    fn eq(&self, other: &Self) -> bool {
        (self.name == other.name) && (self.direction == other.direction) && (self.num == other.num)
    }
}

#[derive(NifStruct, Clone)]
#[module = "Midiex.VirtualMidiPort"]
pub struct VirtualMidiPort {
    direction: Atom,
    name: String,
    num: usize
}

impl PartialEq for VirtualMidiPort {
    fn eq(&self, other: &Self) -> bool {
        (self.name == other.name) && (self.direction == other.direction) && (self.num == other.num)
    }
}

#[derive(NifMap)]
pub struct NumPorts {
    input: usize,
    output: usize 
}

// MIDI IO related 

pub struct MidiexMidiInputRef(pub Mutex<MidiInput>);
pub struct MidiexMidiOutputRef(pub Mutex<MidiOutput>);

impl MidiexMidiInputRef {
    pub fn new(data: MidiInput) -> Self {
        Self(Mutex::new(data))
    }
}

impl MidiexMidiOutputRef {
    pub fn new(data: MidiOutput) -> Self {
        Self(Mutex::new(data))
    }
}


// List all the ports, taking midi_io as input
#[rustler::nif(schedule = "DirtyCpu")]
fn list_ports() -> Result<Vec<MidiPort>, Error> {

    let mut vec_of_devices: Vec<MidiPort> = Vec::new();

    GLOBAL_MIDI_INPUT_RESULT.with(|midi_input_result| {

        let midi_input = match midi_input_result {
            Ok(midi_device) => midi_device,
            Err(error) => panic!("Problem getting midi input devices. Error: {:?}", error)
        };

        // println!("\nMidi input ports: {:?}\n\r", midi_input.port_count());

        for (i, p) in midi_input.ports().iter().enumerate() {
        
            let port_name = if let Ok(port_name) = midi_input.port_name(&p) { port_name } else { "No device name given".to_string() };
    
                vec_of_devices.push(
                    MidiPort{
                        direction: atoms::input(),
                        name: port_name,
                        num: i,
                        port_ref: ResourceArc::new(FlexiPort::new(MidiexMidiPortRef::Input(MidiInputPort::clone(p))))         
                    });
        
        }
    
    });

    GLOBAL_MIDI_OUTPUT_RESULT.with(|midi_output_result| {

        let midi_output = match midi_output_result {
            Ok(midi_device) => midi_device,
            Err(error) => panic!("Problem getting midi output devices. Error: {:?}", error)
        };

        // println!("Midi output ports: {:?}\n\r", midi_output.port_count());

        for (i, p) in midi_output.ports().iter().enumerate() {  
        
            let port_name = if let Ok(port_name) = midi_output.port_name(&p) { port_name } else { "No device name given".to_string() };
          
                vec_of_devices.push(
                    MidiPort{
                        direction: atoms::output(),
                        name: port_name,
                        num: i,
                        port_ref: ResourceArc::new(FlexiPort::new(MidiexMidiPortRef::Output(MidiOutputPort::clone(p))))
                    });
    
        }

    });

    return Ok(vec_of_devices)

}


#[rustler::nif(schedule = "DirtyCpu")]
fn count_ports() -> Result<NumPorts, Error>{

    let mut num_input_ports = 0;
    let mut num_output_ports = 0;

    GLOBAL_MIDI_INPUT_RESULT.with(|midi_input_result| {

        let midi_input = match midi_input_result {
            Ok(midi_device) => midi_device,
            Err(error) => panic!("Problem getting midi input devices. Error: {:?}", error)
        };

        num_input_ports = midi_input.port_count();

    });

    GLOBAL_MIDI_OUTPUT_RESULT.with(|midi_output_result| {

        let midi_output = match midi_output_result {
            Ok(midi_device) => midi_device,
            Err(error) => panic!("Problem getting midi output devices. Error: {:?}", error)
        };

        num_output_ports = midi_output.port_count();

    });

    return Ok( NumPorts { input: num_input_ports, output:  num_output_ports } )
}




fn on_load(env: Env, _info: Term) -> bool {
  
    // MIDI Input and Output object for the OS
    rustler::resource!(MidiexMidiInputRef, env);
    rustler::resource!(MidiexMidiOutputRef, env);
    
    // MIDI ports (both input and output)
    rustler::resource!(FlexiPort, env);
    rustler::resource!(MidiexMidiPortRef, env);

    // MIDI connection to a MIDI port
    // rustler::resource!(FlexiConn, env);
    // rustler::resource!(MidiexConnRef, env);
    rustler::resource!(OutConnRef, env);
    // rustler::resource!(InConnRef, env);

    true
}

rustler::init!(
    "Elixir.Midiex.Backend",
    [
        count_ports,
        list_ports,
        connect,
        close_out_conn,
        send_msg,
        subscribe,
        unsubscribe_all_ports,
        unsubscribe_port,
        unsubscribe_port_by_index,
        create_virtual_output_conn,
        create_virtual_input,
        listen,
        subscribe_virtual_input,
        unsubscribe_virtual_port,
        unsubscribe_all_virtual_ports,
        get_subscribed_ports,
        get_subscribed_virtual_ports,
        ],
    load = on_load
);