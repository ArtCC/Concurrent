//
//  NSOperation.swift
//  Concurrencia
//
//  Created by Arturo Carretero Calvo on 29/06/2020.
//  Copyright © 2020 Arturo Carretero Calvo. All rights reserved.
//

import UIKit

// MARK: Functions.
class NSOperation: NSObject {
    
    // BlockOperation es concurrente
    
    func atomicBlockOperation() {
        let operation1 = BlockOperation {
            print("Operación 1 iniciada")
            sleep(2)
            print("Operación 1 finalizada")
        }
        operation1.start()
    }
    
    func multiBlockOperation() {
        let multiOperation = BlockOperation()
        multiOperation.addExecutionBlock {
            sleep(2)
            print("Hello")
        }
        multiOperation.addExecutionBlock {
            sleep(2)
            print("World")
        }
        multiOperation.start()
    }
    
    func addBlockOperationInQueue() {
        let blockOperation = BlockOperation {
            print("Hago cosas")
        }
        
        let queue = OperationQueue()
        queue.addOperation(blockOperation)
        queue.addOperation {
            print("Hago más cosas")
        }
        
        let multiOperation = BlockOperation()
        multiOperation.completionBlock = { // El completionBlock se lanza al terminar todas las operaciones
            print("Finalizado")
        }
        multiOperation.addExecutionBlock {
            sleep(2)
            print("Hello")
        }
        multiOperation.addExecutionBlock {
            sleep(2)
            print("World")
        }
        
        queue.addOperation(multiOperation)
    }
    
    // Paso las vistas para tener las funciones de ejemplo en clases separadas
    func addActivityIndicator(view: UIView) {
        var activityIndicator: UIActivityIndicatorView!
        view.backgroundColor = .white
        activityIndicator = UIActivityIndicatorView(style: .large)
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicator.startAnimating()
        operation(activityIndicator: activityIndicator)
    }
    
    func ejecutarDemoOperaciones() {
        let operacion = Operaciones()
        operacion.start()
        print("Se acabó")
    }
    
    func serialSimulationBlockOperations() {
        let printerQueue = OperationQueue()
        printerQueue.maxConcurrentOperationCount = 1 // Limitamos las operaciones que se ejecutan a la vez, por lo que se simula que sean serializadas en vez de concurrentes
        
        printerQueue.addOperation {
            print("Inicio Ola")
            sleep(1)
            print("Ola")
        }
        printerQueue.addOperation {
            print("Inicio ase")
            sleep(3)
            print("ase")
        }
        printerQueue.addBarrierBlock { // Operación barrera como en GCD
            print("Inicio k")
            sleep(2)
            print("k")
        }
        printerQueue.addOperation {
            print("Inicio programas")
            sleep(2)
            print("programas")
        }
        printerQueue.addOperation {
            print("Inicio o k ase")
            sleep(2)
            print("o k ase")
        }
        
        printerQueue.waitUntilAllOperationsAreFinished()
        print("Se acabó")
    }
    
    func cancelOperations() {
        let numberArray = [(1,2), (3,4), (5,6), (7,8), (9,10), (11,12), (13,14), (15,16), (17,18), (19,20)]
        
        let sumOperation = SumOperation(input: numberArray)
        let queue = OperationQueue()
        
        queue.addOperation(sumOperation)
        
        sleep(5)
        sumOperation.cancel()
        
        sumOperation.completionBlock = {
            print(sumOperation.outputArray)
        }
    }
}

// MARK: Private functions
private extension NSOperation {
    
    func operation(activityIndicator: UIActivityIndicatorView) {
        let queue = OperationQueue.current
        let blockOperation = BlockOperation {
            sleep(10)
            OperationQueue.main.addOperation {
                activityIndicator.stopAnimating()
            }
        }
        queue?.addOperation(blockOperation)
    }
}

// MARK: Other classes for demo.
class Operaciones: NSObject {
    
    let block1 = BlockOperation {
        let tiempo = UInt32.random(in: 1...3)
        print("Cargando 1")
        sleep(tiempo)
        print("1 cargado en \(tiempo) segundos")
    }
    
    let block2 = BlockOperation {
        let tiempo = UInt32.random(in: 4...5)
        print("Cargando 2")
        sleep(tiempo)
        print("2 cargado en \(tiempo) segundos")
    }
    
    @objc let block3 = BlockOperation {
        let tiempo = UInt32.random(in: 1...3)
        print("Cargando 3")
        sleep(tiempo)
        print("3 cargado en \(tiempo) segundos")
    }
    
    let queue = OperationQueue()
    var observation: NSKeyValueObservation?
    
    func start() {
        observation = block3.observe(\.isFinished) { object, change in
            print("Terminó la tarea 3")
        }
        queue.addOperations([block1, block2, block3], waitUntilFinished: true)
    }
}

// MARK: For 6.10 exercise, cancel operations
class SumOperation: Operation {
    let inputArray: [(Int, Int)]
    var outputArray = [Int]()
    
    init(input:[(Int, Int)]) {
        inputArray = input
        super.init()
    }
    
    override func main() {
        outputArray = NSOperation().slowAddArray(inputArray) { progress in
            print("\(progress*100)% realizado")
            return !self.isCancelled
        }
    }
}

// For cancel operations
extension NSOperation {
    
    func slowAdd(_ input: (Int, Int)) -> Int {
        sleep(1)
        return input.0 + input.1
    }
    
    func slowAddArray(_ input: [(Int, Int)], progress: ((Double) -> (Bool))? = nil) -> [Int] {
        var results = [Int]()
        for pair in input {
            results.append(slowAdd(pair))
            if let progress = progress {
                if !progress(Double(results.count) / Double(input.count)) { return results }
            }
        }
        return results
    }
}
