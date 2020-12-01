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

}





// подтверждение операций, выбраных пользователем
enum OperDescription:String {
    case showBalance = "ПОКАЗАТЬ БАЛАНС СЧЕТА"
    case cashFromDepo = "СНЯТИЕ НАЛИЧНЫХ"
    case toppedUpDepo = "ПОПОЛНЕНИЕ ВАШЕГО БАНКОВСКОГО СЧЕТА НАЛИЧНЫМИ"
    case toppedUpMobile = "ПОПОЛНЕНИЕ СЧЁТА МОБИЛЬНОГО ТЕЛЕФОНА "
    case toppedWithCash =   "НАЛИЧНЫМИ"
    case toppedFromDepo = "C ВАШЕГО БАНКОВСКОГО СЧЕТА"
    
    //
}

enum Phrase:String {
    case hello = "Здравствуте, "
    case thankyouBye = "Спасибо, всего Вам доброго. До свидания"
    case yourChoice = "Вы выбрали операцию: "
    case summa = "сумма"
}


// действия, которые пользователь может выбирать в банкомате
enum UserActions{
    case balanceRequest
    case cashWithdrawal
    case accountTopUp
    case phoneTopUp
}

enum PaymentMethod {
    case withCash
    case fromAccount
}

protocol BankApi{
    func showUserBalance()->Float
    func showUserName() -> String // возвращает имя клиента
    func showUserToppedUpMobilePhoneCash(cash:Float)
    func showUserToppedUpMobilePhoneDeposit(deposit:Float)
    func showWithdrawalDposit(cash:Float)
    func showTopUpAccount(cash:Float)
    func showError(error:TextErrors)
    func checkUserPhone(phone:String) -> Bool
    func checkMaxUseCash(cash:Float) -> Bool
    func checkMaxAccountDeposit(withdraw:Float) -> Bool
    func checkCurrentUser(userCardId:String, userCardPin:Int) -> Bool
    // в оригинале дальше идут mutating func
    mutating func topUpPhoneBalanceCash(pay:Float)
    mutating func topUpPhoneBalanceDeposit(pay:Float)
    mutating func getCashFromDeposit(cash:Float)
    mutating func putCashDeposit(topUp:Float)
}

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

class ATM{
    private let userCardId:String
    private let userCardPin:Int
    private var someBank:BankApi
    private let action:UserActions
    private let operSum:Float
    private let paymentMethod:PaymentMethod?
    
    private let thankyouBye = "Спасибо, всего Вам доброго. До свидания."
    private let hello = "Здравствуйте, "
    
    init(userCardId:String, userCardPin:Int, someBank:BankApi, action: UserActions,operSum:Float, paymentMethod:PaymentMethod?=nil) {
        self.userCardId = userCardId
        self.userCardPin = userCardPin
        self.someBank = someBank
        self.action = action
        self.operSum = operSum
        self.paymentMethod = paymentMethod
        self.sendUserDataToBank()
    }
    public final func sendUserDataToBank(){
        // если данные клиента на сервере совпадают -  продолжаем, нет уходим с
        // сообщением об ошибке
        if !someBank.checkCurrentUser(userCardId: self.userCardId, userCardPin: self.userCardPin) {
            let error = TextErrors.icorrectCardOrPin
            print(error.rawValue)
            return
        }
        switch action {
        //  клиент запросил баланс
        case .balanceRequest:
            print("""
                \(Phrase.hello.rawValue) \(someBank.showUserName()).
                \(Phrase.yourChoice.rawValue) \(OperDescription.showBalance.rawValue),
                Ваш баланс - \(someBank.showUserBalance()).
                \(Phrase.thankyouBye.rawValue)
                """)
        // клиент запросил снятие наличных
        case .cashWithdrawal:
            print("""
                \(Phrase.hello.rawValue) \(someBank.showUserName()).
                \(Phrase.yourChoice.rawValue) \(OperDescription.cashFromDepo.rawValue) \(Phrase.summa.rawValue) \(operSum)
                """)
            //если на счете денег недостаточно уходим с сообщением обошибке
            if !someBank.checkMaxAccountDeposit(withdraw: operSum){
                print(TextErrors.notEnoughFunds.rawValue)
                return
            }
            // запрос на сервер на снятие и изменение остатков на депозите и в кармане
            someBank.getCashFromDeposit(cash: operSum)
            print("""
                Ваш новый баланс - \(someBank.showUserBalance())
                \(Phrase.thankyouBye.rawValue)
                """)
        case .accountTopUp:
            print("""
                \(Phrase.hello.rawValue) \(someBank.showUserName()).
                \(Phrase.yourChoice.rawValue) \(OperDescription.toppedUpDepo.rawValue)
                \(Phrase.summa.rawValue)  \(operSum)
                """)
            //если в кармане нет достаточно денег - уходим
            if !someBank.checkMaxUseCash(cash: operSum) {
                print(TextErrors.notEnoughCash.rawValue)
                return
            }
            someBank.putCashDeposit(topUp:operSum)
            print("""
                Ваш новый баланс - \(someBank.showUserBalance())
                \(Phrase.thankyouBye.rawValue)
                """)
        case .phoneTopUp:
            if self.paymentMethod == PaymentMethod.withCash{
                print(OperDescription.toppedWithCash.rawValue)
            }
            if self.paymentMethod == PaymentMethod.fromAccount{
                print(OperDescription.toppedFromDepo.rawValue)
            }
            
        }
        
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
        return true
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
        //
    }
    
    func topUpPhoneBalanceDeposit(pay: Float) {
        //
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

let misha_mishin:UserData = User(userName: "Миша Мишин", userCardId: "3339 4455 1100 3388", userCardPin: 1987, userCash: 4590.80, userBankDeposit: 12782.78, userPhone: "+7(950)555-33-44", userPhoneBalance: 75.01)

let bankClient = BankServer(user: misha_mishin)



//let atm445 = ATM(userCardId: "fdff", userCardPin: 1987, someBank: bankClient, action: UserActions.cashWithdrawal, operSum: 49)
//
//let atm777 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 1987, someBank: bankClient, action: UserActions.phoneTopUp, operSum: 49, paymentMethod: PaymentMethod.fromAccount)
//
//let atm222 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 1987, someBank: bankClient, action: UserActions.balanceRequest, operSum: 49)

//let atm111 = ATM(userCardId: "3339 4455 1100 3389", userCardPin: 1987, someBank: bankClient, action: UserActions.balanceRequest, operSum: 49)
//let atm222 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 1987, someBank: bankClient, action: UserActions.cashWithdrawal, operSum: 12782.78)
//let atm333 = ATM(userCardId: "3339 4455 1100 3388", userCardPin: 1987, someBank: bankClient, action: UserActions.balanceRequest, operSum: 49)
//print("\n\n\n")
let atm444 = ATM(userCardId: "3339 4455 1100 3389", userCardPin: 1987, someBank: bankClient, action: UserActions.accountTopUp, operSum: 5000)




// print(misha_mishin.userPhoneBalance)
