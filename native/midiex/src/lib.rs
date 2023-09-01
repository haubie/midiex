// #![allow(unused)]
// #![feature(drain_filter)]
extern crate midir;

#[macro_use]
extern crate lazy_static;

#[cfg(all(target_os = "macos"))]
use core_foundation::runloop::CFRunLoop;
#[cfg(all(target_os = "macos"))]
use coremidi::{Client, Notification, AddedRemovedInfo, ObjectType};
#[cfg(all(target_os = "macos"))]
use coremidi::Notification::{ObjectAdded, ObjectRemoved};

use std::sync::Mutex;
use std::result::Result;
use std::ops::{DerefMut, Add};

use midir::{MidiInput, MidiOutput, MidiOutputConnection, MidiInputPort, MidiOutputPort, Ignore, InitError};
use midir::os::unix::{VirtualInput, VirtualOutput};

use rustler::{Atom, Env, Error, NifStruct, NifMap, ResourceArc, Term, Binary, OwnedEnv, Encoder};


// --------------
// GLOBALS
// --------------

// IS THIS NEEDED ANYMORE?
// This version uses threadlocal to create the MidiInput and MidiOutput objects
thread_local!(static GLOBAL_MIDI_INPUT_RESULT: Result<MidiInput, InitError> = MidiInput::new("MIDIex"));
thread_local!(static GLOBAL_MIDI_OUTPUT_RESULT: Result<MidiOutput, InitError> = MidiOutput::new("MIDIex"));


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


// --------------
// ATOMS
// --------------

pub mod atoms {
    rustler::atoms! {
        ok,
        error,

        input,
        output,

        device,
        entity,
        other,

        message,

        added,
        removed
    }
}


// ----------
// SUBSCRIBE
// ----------

#[rustler::nif]
fn unsubscribe_all_ports() -> Result<Vec<MidiPort>, Error> {
    GLOBAL_LISTEN_LIST.lock().unwrap().clear();
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn unsubscribe_port(midi_port: MidiPort) -> Result<Vec<MidiPort>, Error> {
    GLOBAL_LISTEN_LIST.lock().unwrap().retain(|x| *x != midi_port);
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn unsubscribe_port_by_index(port_num: usize) -> Result<Vec<MidiPort>, Error> {  
    GLOBAL_LISTEN_LIST.lock().unwrap().retain(|x| x.num != port_num);
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn get_subscribed_ports() -> Result<Vec<MidiPort>, Error> {
    Ok(GLOBAL_LISTEN_LIST.lock().unwrap().to_vec()) 
}

#[rustler::nif]
pub fn subscribe(env: Env, midi_port: MidiPort) -> Atom {    
    // Add the whole port struct to a listeners Vec

    let mut g_list_lock = GLOBAL_LISTEN_LIST.lock().unwrap();
    g_list_lock.push(midi_port.clone());
    g_list_lock.sort_unstable_by_key(|midi_port| (midi_port.num));
    g_list_lock.dedup();


    let m_port_clone = midi_port.clone();

    let pid = env.pid();
    
    let mut owned_env = OwnedEnv::new();

    std::thread::spawn(move || {

        let mut midi_in = MidiInput::new("MIDIex input").expect("Midi input");
        midi_in.ignore(Ignore::None);

        let in_port = match &midi_port.port_ref.0 {
            MidiexMidiPortRef::Input(in_port) => in_port,
            MidiexMidiPortRef::Output(_out_port) => panic!("Midi Input Port Error: Problem getting midi input port reference.")
        };

        let _conn_in = midi_in
            .connect(
                &in_port,
                "midir-read-input",
                move |stamp, message, _| {

                    owned_env.send_and_clear(&pid, |the_env| {
                        // message.encode(the_env)

                        let m_port_clone = m_port_clone.clone();

                        MidiMessage{  
                            data: message.to_vec(),
                            port: m_port_clone,
                            timestamp: stamp
                        }.encode(the_env)
                    });
                    ()
                },
                (),
            )
            .unwrap();

        let mut still_listen = true;
        while still_listen {
            still_listen = GLOBAL_LISTEN_LIST.lock().unwrap().contains(&midi_port);
        }

        _conn_in.close();

    });

    atoms::ok()
}

// ------------------
// VIRTUAL INPUT
// ------------------

#[rustler::nif]
fn create_virtual_input(port_name: String) -> Result<VirtualMidiPort, Error> {

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
fn unsubscribe_virtual_port(virtual_midi_port: VirtualMidiPort) -> Result<Vec<VirtualMidiPort>, Error> {  
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().retain(|virt_port| virt_port != &virtual_midi_port);
    Ok(GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn unsubscribe_all_virtual_ports() -> Result<Vec<VirtualMidiPort>, Error> {
    GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().clear();
    Ok(GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().to_vec())
}

#[rustler::nif]
fn get_subscribed_virtual_ports() -> Result<Vec<VirtualMidiPort>, Error> {
    Ok(GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().to_vec()) 
}


// This replaces all other create_virtual_input stuff
#[rustler::nif]
pub fn subscribe_virtual_input(env: Env, virtual_midi_port: VirtualMidiPort) -> Atom {    

    let mut gv_list_lock = GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap();
    gv_list_lock.push(virtual_midi_port.clone());
    gv_list_lock.sort_unstable_by_key(|midi_port| (midi_port.num));
    gv_list_lock.dedup();

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
            still_listen = GLOBAL_VIRTUAL_LISTEN_LIST.lock().unwrap().contains(&virtual_midi_port);
        }

        _conn_in.close();

    });

    atoms::ok()
}


// ---------------------------------------
// NOTIFICATIONS AND HOTPLUG
// ---------------------------------------
// Supported on MacOS only at the moment
// ---------------------------------------

#[cfg(all(target_os = "macos"))]
#[rustler::nif]
pub fn notifications(env: Env) -> Result<Atom, Error> {

    let pid = env.pid();
    let mut owned_env = OwnedEnv::new();
    
    std::thread::spawn(move || { 
            
        let cb_fb = move |notification: &Notification| {

        match notification {
            ObjectAdded(info) => owned_env.send_and_clear(&pid, |the_env| {
                MidiNotification::new(atoms::added(), info).encode(the_env)
            }),
            ObjectRemoved(info) => owned_env.send_and_clear(&pid, |the_env| {
                MidiNotification::new(atoms::removed(), info).encode(the_env)
            }),
                _ => (),
            };
        
        };
    
        let _client = Client::new_with_notifications("MIDIex notifications client", cb_fb).unwrap();
        CFRunLoop::run_current();
    });

    Ok(atoms::ok())
}

#[cfg(not(any(target_os = "macos")))]
#[rustler::nif]
pub fn notifications() -> Result<Atom, Error> {
    Err(Error::RaiseTerm(Box::new(
        "Notications are not yet enabled for this platform (currently MacOS only)".to_string(),
    )))
}

#[cfg(all(target_os = "macos"))]
#[rustler::nif]
pub fn hotplug() -> Result<Atom, Error> {

    std::thread::spawn(move || {        
        let cb_fb = move |_notification: &Notification| {}; 
        let _client = Client::new_with_notifications("MIDIex notifications client", cb_fb).unwrap();
        CFRunLoop::run_current();
    });

    Ok(atoms::ok())
}


#[cfg(not(any(target_os = "macos")))]
#[rustler::nif]
pub fn hotplug() -> Result<Atom, Error> {
    Err(Error::RaiseTerm(Box::new(
        "Hotplug is not yet enabled for this platform (currently MacOS only)".to_string(),
    )))
}


// ------------------
// OUTPUT CONNECTION
// ------------------

#[rustler::nif]
fn connect(midi_port: MidiPort) -> Result<OutConn, Error>{

    if midi_port.direction == atoms::output()  {
        // println!("OUTPUT");

        let midi_output = MidiOutput::new("MIDIex").expect("Midi output");  

        // let mut port_ref = midi_port.port_ref.0;

        if let MidiexMidiPortRef::Output(port) = &midi_port.port_ref.0 { 

            // println!("OUTPUT PORT");

            let conn_out_result = midi_output.connect(&port, "MIDIex");

            let mut _conn_out = match conn_out_result {
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

        // let mut midi_input = MidiInput::new("MIDIex").expect("Midi output");  

        // let mut port_ref = midi_port.port_ref.0;

        if let MidiexMidiPortRef::Input(_port) = &midi_port.port_ref.0 { 

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

// ------------------------
// OUPUT CONNECTION CLOSING
// ------------------------

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


// ------------------------
// VIRTUAL OUPUT
// ------------------------

#[rustler::nif]
fn create_virtual_output_conn(name: String) -> Result<OutConn, Error>{

    let midi_output = MidiOutput::new("MIDIex").expect("Midi output");
    let mut midi_input = MidiInput::new("MIDIex").expect("Midi input");
    midi_input.ignore(Ignore::None);

    let conn_out = midi_output.create_virtual(&name).expect("Midi MidiOutputConnection");

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

// ------------------------
// SENDING MIDI MESSAGES
// ------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn send_msg(midi_out_conn: OutConn, message: Binary) -> Result<OutConn, Error>{
    { 
        let mut binding = midi_out_conn.conn_ref.0.lock().unwrap();
        let out_conn = binding.deref_mut();

        let _res = match out_conn {
                Some(conn) => conn.send(&message),
                None => return Err(Error::RaiseTerm(Box::new(
                    "No output connection available to send message to. Connection may have been closed.".to_string(),
                ))),
            };
    }
    
    Ok(midi_out_conn)
}



// =================
// MIDI Message
// =================
#[derive(NifStruct)]
#[module = "Midiex.MidiMessage"]
pub struct MidiMessage {
    port: MidiPort,
    data: Vec<u8>,
    timestamp: u64
}

// =================
// MIDI Notification
// =================
#[derive(NifStruct)]
#[module = "Midiex.MidiNotification"]
pub struct MidiNotification {
    notification_type: Atom,
    parent_name: String,
    parent_id: u32,
    parent_type: Atom,
    name: String,
    native_id: u32,
    direction: Atom
}

impl MidiNotification {
    pub fn new(notification_type: Atom, info: &AddedRemovedInfo) -> Self {

        let parent_name = match info.parent.name() {
            Some(name) => name,
            None => "".to_string()
        };

        let parent_id = match info.parent.unique_id() {
            Some(id) => id,
            None => 0
        };

        let child_name = match info.child.display_name() {
            Some(name) => name,
            None => "".to_string()
        };

        let child_id = match info.child.unique_id() {
            Some(id) => id,
            None => 0
        }; 

        Self{
            notification_type: notification_type,
            parent_name: parent_name,
            parent_id: parent_id,
            parent_type: midi_obj_type_to_atom(info.parent_type),
            name: child_name,
            native_id: child_id,
            direction: midi_obj_type_to_atom(info.child_type)
        }
        
    }
}

fn midi_obj_type_to_atom(object_type: ObjectType) -> Atom {
    match object_type {
        ObjectType::Other => atoms::other(),
        ObjectType::Device => atoms::device(),
        ObjectType::Entity => atoms::entity(),
        ObjectType::Source => atoms::input(),
        ObjectType::Destination => atoms::output(),
        ObjectType::ExternalDevice => atoms::device(),
        ObjectType::ExternalEntity => atoms::entity(),
        ObjectType::ExternalSource => atoms::input(),
        ObjectType::ExternalDestination => atoms::output(),
    }
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


// ------------------------
// LIST PORTS
// ------------------------

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


// ------------------------
// COUNT PORTS
// ------------------------


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


// ------------------------
// RUSTLER
// ------------------------


fn on_load(env: Env, _info: Term) -> bool {
  
    // MIDI Input and Output object for the OS
    rustler::resource!(MidiexMidiInputRef, env);
    rustler::resource!(MidiexMidiOutputRef, env);
    
    // MIDI ports (both input and output)
    rustler::resource!(FlexiPort, env);
    rustler::resource!(MidiexMidiPortRef, env);

    // MIDI connection to a MIDI port
    rustler::resource!(OutConnRef, env);

    // MIDI notification
    rustler::resource!(MidiNotification, env);

    // MIDI message
    rustler::resource!(MidiMessage, env);
    
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
        subscribe_virtual_input,
        unsubscribe_virtual_port,
        unsubscribe_all_virtual_ports,
        get_subscribed_ports,
        get_subscribed_virtual_ports,
        notifications,
        hotplug
        ],
    load = on_load
);