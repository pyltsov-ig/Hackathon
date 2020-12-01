//  Абстракция данных пользователя
protocol UserData{

    var userName:String {get} //имя пользователя
    var userCardId:String {get} // номер карты
    var userCardPin:Int {get} // пин-код
    var userCash:Float {get set} // наличные клиента
    var userBankDeposit:Float{get set} // банковсий депозит
    var userPhone:String {get} //номер телефона
    var userPhoneBalance:Float{get set} //баланс телефона
    
}

// тексты ошибок

enum TextErrors:String{
    case icorrectCardOrPin  =   """
                                Неверный номер карты или ПИН-код
                                Уточние данные и попробуйте снова.
                                """
    case incorrectCardNumber =  "Неверный номер карты"
    case cardNotReadibg      =   "Карта не читается."
    case notEnoughFunds      = """
                                К сожалению на Вашем счете недостаточно средств,
                                измените сумму и попробуйте снова.
                                """
    case notEnoughCash      =   """
                                К сожалению у Вас в кармане нет столько денег,
                                измените сумму или займите еще денег у кого-нибудь.
                                """
    case incorrectPhoneNum  =   """
                                Неправильно указан номер телефона.
                                Проверьте введенные данные и попробуйте снова.
                                """

}





// подтверждение операций, выбраных пользователем
// в данном варианте решения перечисление не используется
// вместо нее используется ассоциированные значения в UserActions
enum OperDescription:String {
    case showBalance
    case cashFromDepo
    case toppedUpDepo
    case toppedUpMobile
    case toppedWithCash
    case toppedFromDepo
    
    //
}




// действия, которые пользователь может выбирать в банкомате
// сюда еще добавлена сумма операции и номер телефона клиента как вычисляемые свойства

enum UserActions{
    case balanceRequest(operName:String = "Запрос баланса")
    case cashWithdrawal(operName:String = "Выдача наличных")
    case accountTopUp(operName:String = "Пополнение депозита")
    case phoneTopUp(operName:String = "Пополнение счета телефона")
    var operSum:Float {return 1500.0}
    var phoneNumber:String {return "+7(950)555-33-44"}
}

enum PaymentMethod {
    case withCash(method:String = "НАЛИЧНВМИ")
    case fromAccount(method:String = "БЕЗНАЛИЧНВМИ")
}

protocol BankApi{
    func showUserBalance()->Float // возвращает остаток на банковском депозите
    func showUserName() -> String // возвращает имя клиента
    func showUserPhoneBalance() -> Float // возвращает остаток на мобильном
    func showUserToppedUpMobilePhoneCash(cash:Float)
    func showUserToppedUpMobilePhoneDeposit(deposit:Float)
    func showWithdrawalDposit(cash:Float)
    func showTopUpAccount(cash:Float)
    func showError(error:TextErrors)
    func checkUserPhone(phone:String) -> Bool
    func checkMaxUseCash(cash:Float) -> Bool
    func checkMaxAccountDeposit(withdraw:Float) -> Bool
    func checkCurrentUser(userCardId:String, userCardPin:Int) -> Bool
    mutating func topUpPhoneBalanceCash(pay:Float)
    mutating func topUpPhoneBalanceDeposit(pay:Float)
    mutating func getCashFromDeposit(cash:Float)
    mutating func putCashDeposit(topUp:Float)
}

// класс используется для создания экземляра или экземпляров
// банковских клиентов в банке
// что-то типа БД может быть
class User:UserData{
    var userName: String
    var userCardId: String
    var userCardPin: Int
    var userCash: Float
    var userBankDeposit: Float
    var userPhone: String
    var userPhoneBalance: Float
    init(userName:String, userCardId:String, userCardPin:Int, userCash:Float, userBankDeposit:Float, userPhone:String, userPhoneBalance:Float) {
        self.userName = userName
        self.userCardId = userCardId
        self.userCardPin = userCardPin
        self.userCash = userCash
        self.userBankDeposit = userBankDeposit
        self.userPhone = userPhone
        self.userPhoneBalance = userPhoneBalance
    }
    
}

// класс ATM реализует логику работы интерфейса пользователя при работе с банкоматом
// включая пользовательский интерфейс и вывод текста об ошибках.
// реализован с помощью оператора switch с перечеслением actions:UserActions,
// а также с вложенным в него вторым оператором switch с перечилением paymentMethod:PaymentMetod для определения способа оплаты.
class ATM{
    private let userCardId:String
    private let userCardPin:Int
    private var someBank:BankApi
    private let action:UserActions
    private let paymentMethod:PaymentMethod?
    
    init(userCardId:String, userCardPin:Int, someBank:BankApi, action:UserActions, paymentMethod:PaymentMethod?=nil) {
        self.userCardId = userCardId
        self.userCardPin = userCardPin
        self.someBank = someBank
        self.action = action
        self.paymentMethod = paymentMethod
        self.sendUserDataToBank()
    }
    private final func sendUserDataToBank(){
        // если проверка клиента в банке не прошла, то уходим
        if !someBank.checkCurrentUser(userCardId: self.userCardId, userCardPin: self.userCardPin) {
            let error = TextErrors.icorrectCardOrPin
            print(error.rawValue)
            return
        }
        // если все в порядке, то продолжаем
        print("Здравствуйте, \(someBank.showUserName()) Вы выбрали операцию:")
        switch self.action {
        case .balanceRequest(operName: let operName):
            print(operName)
            print("Баланс Вашего счета равен: \(someBank.showUserBalance()) рубля(ей)")
        case .cashWithdrawal(operName: let operName):
            print("\(operName), сумма: \(action.operSum)")
            if !someBank.checkMaxAccountDeposit(withdraw: action.operSum){
                let error = TextErrors.notEnoughFunds
                print(error.rawValue)
                return
            }
            someBank.getCashFromDeposit(cash: action.operSum)
            print("Ваш новый баланс счета: \(someBank.showUserBalance())")
        case .accountTopUp(operName: let operName):
            print("\(operName) на сумму: \(action.operSum)")
            if !someBank.checkMaxUseCash(cash: action.operSum){
                let error = TextErrors.notEnoughCash
                print(error.rawValue)
                return
            }
            someBank.putCashDeposit(topUp: action.operSum)
            print("Ваш новый баланс счета: \(someBank.showUserBalance()) рубля(ей)")
        case .phoneTopUp(operName: let operName):
            // проверяем номер телефона, если плохо, то уходим
            if !someBank.checkUserPhone(phone: action.phoneNumber) {
                let error = TextErrors.incorrectPhoneNum
                print(error.rawValue)
                return
            }
            print("\(operName) на сумму \(action.operSum) рублей")
            print("Номер телефона: \(action.phoneNumber)")
            switch paymentMethod{
            case .withCash(method: let method):
                print("\(method)")
                if !someBank.checkMaxUseCash(cash: action.operSum) {
                    let error = TextErrors.notEnoughCash
                    print(error.rawValue)
                    return
                }
                someBank.topUpPhoneBalanceCash(pay: action.operSum)
            case .fromAccount(method: let method):
                print("\(method)")
                if !someBank.checkMaxAccountDeposit(withdraw: action.operSum){
                    let error = TextErrors.notEnoughFunds
                    print(error.rawValue)
                    return
                }
                someBank.topUpPhoneBalanceDeposit(pay: action.operSum)
            case .none:
                print("ЭТО НЕ ВЫПОЛНИТСЯ НИКОГДА")
                return
            }
            print("Ваш новый баланс счета \(someBank.showUserBalance()) рубля(ей)")
            print("Ваш баланс счета мобильного тедлефона \(someBank.showUserPhoneBalance())")
        } // конец свича :)
     print("До свидания и хорошего дня!")
    }
}

// класс ATMS предназначен для реализации задачи через методы с префиксом show,
// которые не использовались в реализации класса ATM. В этом случае обработка ошибок
// будет вестись на сервере
// сейчас это еще не реализовано. Релизую когда будет время.
//
class ATMS{
    private let userCardId:String
    private let userCardPin:Int
    private var someBank:BankApi
    private let action:UserActions
    private let paymentMethod:PaymentMethod?
    
    init(userCardId:String, userCardPin:Int, someBank:BankApi, action:UserActions, paymentMethod:PaymentMethod?=nil) {
        self.userCardId = userCardId
        self.userCardPin = userCardPin
        self.someBank = someBank
        self.action = action
        self.paymentMethod = paymentMethod
        self.sendUserDataToBank()
    }
    private final func sendUserDataToBank(){
        //
    }

}



class BankServer:BankApi{
    
    private var user:UserData
    
    init (user:UserData){
        self.user = user
    }
    
    func showUserBalance() -> Float {
        return user.userBankDeposit
    }
    func showUserName() -> String {
        return self.user.userName
    }
    func showUserPhoneBalance() -> Float{
        return self.user.userPhoneBalance
    }
    func showUserToppedUpMobilePhoneCash(cash: Float) {
        //
    }
    
    func showUserToppedUpMobilePhoneDeposit(deposit: Float) {
        //
    }
    
    func showWithdrawalDposit(cash: Float) {
        //
    }
    
    func showTopUpAccount(cash: Float) {
        //
    }
    
    func showError(error: TextErrors) {
        //
    }
    
    func checkUserPhone(phone: String) -> Bool {
        if self.user.userPhone == phone {
            return true
        } else {
            return false
        }
        
    }
    
    func checkMaxUseCash(cash: Float) -> Bool {
        if self.user.userCash < cash {
            return false
        }
        return true
    }
    
    func checkMaxAccountDeposit(withdraw: Float) -> Bool {
        if self.user.userBankDeposit < withdraw {
            return false
        }
        return true
    }
    
    func checkCurrentUser(userCardId: String, userCardPin: Int) -> Bool {
        if (userCardId != self.user.userCardId) || (userCardPin != self.user.userCardPin){
            return false
        }
        return true
    }
    
    func topUpPhoneBalanceCash(pay: Float) {
        self.user.userCash -= pay
        self.user.userPhoneBalance += pay
    }
    
    func topUpPhoneBalanceDeposit(pay: Float) {
        self.user.userBankDeposit -= pay
        self.user.userPhoneBalance += pay
    }
    
    func getCashFromDeposit(cash: Float) {
        self.user.userCash += cash
        self.user.userBankDeposit -= cash
    }
    
    func putCashDeposit(topUp: Float) {
        self.user.userCash -= topUp
        self.user.userBankDeposit += topUp
    }
    
    
}


// создание базы данных клиентов банка, это маленький банк - только один клиент

let misha_mishin:UserData = User(userName: "Миша Мишин", userCardId: "3339 4455 1100 3388", userCardPin: 2222, userCash: 50000.80, userBankDeposit: 12782.78, userPhone: "+7(950)555-33-44", userPhoneBalance: 75.01)

let bankClient = BankServer(user: misha_mishin)


//клиент работает с банкоматом


print("\n ***** запрос баланса на банковском депозите ***** \n")
let userChoice100 = UserActions.balanceRequest()
let atm100 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 2222, someBank: bankClient, action: userChoice100)

print("\n ***** снятие наличных с банковского депозита ***** \n")
let userChoice200 = UserActions.cashWithdrawal()
let atm200 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 2222, someBank: bankClient, action: userChoice200)

print("\n ***** пополнение банковского депозита наличными ***** \n")
let userChoice300 = UserActions.accountTopUp()
let atm300 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 2222, someBank: bankClient, action: userChoice300)

print("\n ***** пополнение баланса телефона с банковского депозита ***** \n")
let userChoice400 = UserActions.phoneTopUp()
let payMeth400 = PaymentMethod.fromAccount()
let atm400 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 2222, someBank: bankClient, action: userChoice400, paymentMethod: payMeth400)

print("\n ***** пополнение баланса телефона наличными ***** \n")
let userChoice500 = UserActions.phoneTopUp()
let payMeth500 = PaymentMethod.withCash()
let atm500 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 2222, someBank: bankClient, action: userChoice400, paymentMethod: payMeth500)




