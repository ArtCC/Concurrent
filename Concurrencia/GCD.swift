//
//  GCD.swift
//  Concurrencia
//
//  Created by Arturo Carretero Calvo on 29/06/2020.
//  Copyright © 2020 Arturo Carretero Calvo. All rights reserved.
//

import UIKit

// MARK: Functions.
class GCD: NSObject {

    func simpleDispatchQueue() {
        DispatchQueue.main.async {
            print("Hola main")
        }
        
        DispatchQueue.global().async {
            print("Hola global")
        }
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 5.0) {
            print("Global concurrente pasados 5 segundos")
        }
        
        let dispatch = DispatchQueue(label: "com.artcc.serial")
        let dispatchC = DispatchQueue(label: "com.artcc.concurrent", qos: .userInteractive, attributes: .concurrent)
        
        dispatch.sync {
            print("Hola")
        }
        
        dispatchC.schedule(after: .init(.now() + 86400.0), tolerance: .seconds(1)) {
            print("Acción programada para mañana")
        }
        
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            print("Iteración: \(index)")
        }
    }
    
    func groupsDispatchQueue() {
        // Grupos (usar el group.enter() hereda del hilo donde esté, si no hay ninguno definido será el main)
        DispatchQueue.global(qos: .userInteractive).async {
            let group = DispatchGroup()
            
            DispatchQueue.global().async(group: group) {
                print("Tarea de ejecución")
            }
            
            group.enter() // Meterlo en el grupo
            print("Hola grupo 1")
            group.leave() // Sacarlo del grupo
            
            func load(delay: UInt32, completion:() -> ()) {
                sleep(delay)
                completion()
            }
            
            group.enter()
            load(delay: 2) {
                print("Hola Grupo 2")
                group.leave()
            }
            
            group.notify(queue: .main) {
                print("Tareas terminadas")
            }
        }
    }
    
    func itemsDispatchQueue() {
        let dispatch = DispatchQueue(label: "com.artcc.serial")
        let dispatchC = DispatchQueue(label: "com.artcc.concurrent", qos: .userInteractive, attributes: .concurrent)
        
        // Items
        let item1 = DispatchWorkItem {
            print("Hola 1")
        }
        
        let item2 = DispatchWorkItem {
            print("Hola 2")
            dispatchC.async(execute: item1)
        }
        
        dispatchC.async(execute: item2)
        
        let item3 = DispatchWorkItem(qos: .userInitiated, flags: .assignCurrentContext) {
            print("Hola 3")
        }
        
        dispatch.sync(execute: item3)
    }
    
    func groupsAndWaitDispatchQueue() {
        // Agrupando y esperando
        let queue = DispatchQueue.global(qos: .userInteractive)
        let group = DispatchGroup()
        
        for i in 1...6 {
            queue.async(group: group) {
                let tiempo = UInt32.random(in: 2...7)
                print("Iniciada tarea \(i) en \(tiempo) segundos")
                sleep(tiempo)
                print("Tarea \(i) finalizada")
            }
        }
        
        group.wait() // Cuando todas las tareas finalicen seguirá la ejecución
        //group.wait(timeout: .now() + 5.0) // Lo mismo con time out para que no se pare eternamente
        
        print("Hola estoy aquí")
    }
    
    func serialDispatchQueue() {
        // Tareas serializadas
        let serialQueue = DispatchQueue(label: "com.queue.serial")
        serialQueue.async {
            print("Comienzo tarea 1")
            sleep(2)
            print("Finalizo tarea 1")
        }
        
        serialQueue.async {
            print("Comienzo tarea 2")
            sleep(2)
            print("Finalizo tarea 2")
        }
        
        serialQueue.async {
            print("Comienzo tarea 3")
            sleep(2)
            print("Finalizo tarea 3")
        }
    }
    
    func concurrentDispatchQueue() {
        // Tareas concurrentes
        let concurrentQueue = DispatchQueue(label: "com.queue.concurrent", attributes: .concurrent)
        concurrentQueue.async {
            print("Comienzo concurrente tarea 1")
            sleep(2)
            print("Finalizo concurrente tarea 1")
        }
        
        concurrentQueue.async {
            print("Comienzo concurrente tarea 2")
            sleep(2)
            print("Finalizo concurrente tarea 2")
        }
        
        concurrentQueue.async {
            print("Comienzo concurrente tarea 3")
            sleep(2)
            print("Finalizo concurrente tarea 3")
        }
    }
    
    func barrierTaskDispatchQueue() {
        // Pasar función al item. Tareas barrera (caso 3)
        let group = DispatchGroup()
        let workQueue = DispatchQueue(label: "com.queue.concurrent", attributes: .concurrent)
        
        func caso1() {
            print("Comienzo tarea 1 concurrente")
            sleep(4)
            print("Fin tarea 1 concurrente")
        }
        
        func caso2() {
            print("Comienzo tarea 2 concurrente")
            sleep(7)
            print("Fin tarea 2 concurrente")
        }
        
        func caso3Barrera() {
            print("Comienzo tarea 3 concurrente barrera")
            sleep(3)
            print("Fin tarea 3 concurrente barrera")
        }
        
        func caso4() {
            print("Comienzo tarea 4 concurrente")
            sleep(3)
            print("Fin tarea 4 concurrente")
        }
        
        func caso5() {
            print("Comienzo tarea 5 concurrente")
            sleep(1)
            print("Fin tarea 5 concurrente")
        }
        
        let workItem1 = DispatchWorkItem(block: caso1)
        let workItem2 = DispatchWorkItem(block: caso2)
        let workItem3Barrera = DispatchWorkItem(qos: .utility, flags: .barrier, block: caso3Barrera)
        let workItem4 = DispatchWorkItem(block: caso4)
        let workItem5 = DispatchWorkItem(block: caso5)
        
        workQueue.async(group: group, execute: workItem1)
        workQueue.async(group: group, execute: workItem2)
        workQueue.async(group: group, execute: workItem3Barrera) // Hasta que las tareas 1 y 2 no terminen no lanza la 3, cuando acabe la 3 lanza la 4 y la 5
        workQueue.async(group: group, execute: workItem4)
        workQueue.async(group: group, execute: workItem5)
        
        group.notify(queue: .main) {
            print("Todo OK")
        }
    }
    
    func downloadImagesWithWaitDispatchQueue() {
        let urlImages = ["https://applecoding.com/wp-content/uploads/2019/07/cropped-black-and-white-black-and-white-challenge-262488-1024x576.jpg",
                         "https://applecoding.com/wp-content/uploads/2019/07/cropped-company-concept-creative-7369-1-1024x575.jpg",
                         "https://applecoding.com/wp-content/uploads/2018/06/cropped-mapkitjs-portada-1024x576.jpg",
                         "https://applecoding.com/wp-content/uploads/2019/06/combine-operators-1024x573-1024x576.jpg",
                         "https://applecoding.com/wp-content/uploads/2019/06/wwdc_2_0.jpg",
                         "https://applecoding.com/wp-content/uploads/2018/06/header-390x220.jpg",
                         "https://applecoding.com/wp-content/uploads/2018/06/mapkitjs-portada-1024x576.jpg"]
        
        var resultado: [UIImage] = []
        
        DispatchQueue(label: "com.queue.serial").async {
            let downloadGroup = DispatchGroup()
            
            urlImages.forEach {
                if let url = URL(string: $0) {
                    downloadGroup.enter()
                    self.downloadImage(url: url) {
                        resultado.append($0)
                        downloadGroup.leave()
                    }
                }
            }
            
            downloadGroup.wait()
            
            DispatchQueue.main.async {
                print(resultado)
            }
        }
    }
    
    func viewAnimationsWithEndNotificationDispatchQueue() {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        view.backgroundColor = .red
        let box = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        box.backgroundColor = .yellow
        view.addSubview(box)
        
        //self.view.addSubview(view)
        
        let group = DispatchGroup()
        
        UIView.animate(withDuration: 1, animations: {
            box.center = CGPoint(x: 150, y: 150)
        }, group: group, completion: { _ in
            UIView.animate(withDuration: 2, animations: {
                box.transform = CGAffineTransform(rotationAngle: .pi/2)
            }, group: group, completion: { _ in
                UIView.animate(withDuration: 1, animations: {
                    box.center = CGPoint(x: 50, y: 150)
                }, group: group, completion: nil)
            })
        })
        
        UIView.animate(withDuration: 3, animations: {
            view.backgroundColor = .blue
        }, group: group, completion: nil)
        
        group.notify(queue: .main) {
            print("Animations complete!")
        }
    }
    
    func downloadImagesFromURLDispatchQueue() {
        let urlJSON = URL(string: "https://applecodingacademy.com/testData/testImages.json")!
        
        var images: Images?
        var resultado = [UIImage?]()
        
        let downloadGroup = DispatchGroup()
        
        let _ = DispatchQueue.global(qos: .userInitiated) // Para el concurrentPerform inicializamos el .global con su qos así
        
        URLSession.shared.dataTask(with: urlJSON) { data, _, _ in
            guard let data = data else { return }
            images = try? JSONDecoder().decode(Images.self, from: data)
            
            if let images = images {
                resultado = [UIImage?](repeating: nil, count: images.images.count)
                DispatchQueue.concurrentPerform(iterations: images.images.count) { index in
                    downloadGroup.enter()
                    self.downloadImage(url: images.images[index]) { image in
                        resultado[index] = image
                        downloadGroup.leave()
                    }
                }
            }
            
            downloadGroup.notify(queue: .main) {
                let imagesLoad = resultado.compactMap { $0 }
                print(imagesLoad)
                print(imagesLoad.count)
            }
        }.resume()
    }
    
    // Para controlar cuantas tareas se pueden ir ejecutando a la vez. Se libera una, se accede a otra.
    func semaphoreDispatchQueue() {
        let queue = DispatchQueue(label: "com.queue.concurrent", qos: .userInteractive, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 3)
        
        for i in 1...10 {
            queue.async {
                semaphore.wait()
                
                print("Process number \(i)")
                sleep(UInt32.random(in: 2...4))
                print("Process finished \(i)")
                
                semaphore.signal()
            }
        }
    }
    
    func cancelProcessDispatchQueue() {
        let urlImages = [
            "https://applecoding.com/wp-content/uploads/2019/07/cropped-black-and-white-black-and-white-challenge-262488-1024x576.jpg",
            "https://applecoding.com/wp-content/uploads/2019/07/cropped-company-concept-creative-7369-1-1024x575.jpg",
            "https://applecoding.com/wp-content/uploads/2018/06/cropped-mapkitjs-portada-1024x576.jpg",
            "https://applecoding.com/wp-content/uploads/2019/06/combine-operators-1024x573-1024x576.jpg",
            "https://applecoding.com/wp-content/uploads/2019/06/wwdc_2_0.jpg",
            "https://applecoding.com/wp-content/uploads/2018/06/header-390x220.jpg",
            "https://applecoding.com/wp-content/uploads/2018/06/mapkitjs-portada-1024x576.jpg"
        ]
        
        let downloadGroup = DispatchGroup()
        var resultado: [UIImage] = []
        var blocks: [DispatchWorkItem] = []
        
        for address in urlImages {
            let tiempo = Double.random(in: 1...4)
            let block = DispatchWorkItem {
                let url = URL(string: address)!
                downloadGroup.enter()
                self.downloadImage(url: url) { image in
                    sleep(UInt32(tiempo))
                    resultado.append(image)
                    downloadGroup.leave()
                    print("Recuperada imagen \(url.path)")
                }
            }
            blocks.append(block)
            print("URL \(address) retenida \(tiempo) segundos.")
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + tiempo, execute: block)            
        }
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 3) {
            blocks.forEach {
                $0.cancel()
            }
            
            print(resultado)
        }
    }
}

// MARK: Private functions.
private extension GCD {
    
    func downloadImage(url: URL, completionImage: @escaping (UIImage) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                if let error = error {
                    print("Error en la operación \(error)")
                }
                return
            }
            if response.statusCode == 200 {
                if let image = UIImage(data: data) {
                    completionImage(image)
                } else {
                    print("No es una imagen")
                }
            } else {
                print("Error \(response.statusCode)")
            }
        }.resume()
    }
}


// MARK: Extensions
extension UIView {
    static func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, group: DispatchGroup, completion: ((Bool) -> Void)?) {
        group.enter()
        animate(withDuration: duration, animations: animations) { success in
            completion?(success)
            group.leave()
        }
    }
}

// MARK: Structs
struct Images: Codable {
    let images: [URL]
}
