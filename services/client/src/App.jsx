import React, { Component } from 'react';
import axios from 'axios';
import UsersList from './components/UsersList';
import AddUser from './components/AddUser';
import About from './components/About';
import { Route, Switch } from 'react-router-dom';

class App extends Component {
    constructor(){
	super();
	this.state = {
	    users: [],
	    username: '',
	    email: '',
	};
	this.addUser = this.addUser.bind(this);
	this.handleChange = this.handleChange.bind(this);
    }

    componentDidMount(){
	this.getUsers();
    }

    render(){
	return (
	<div className="container">
	  <div className="row">
	    <div className="col-md-6">
	      <br/>
	      <Switch>
		<Route exact path='/' render={() => (
		  <div>
		    <h1>All Users</h1>
		    <hr/><br/>
		    <AddUser
		      username={this.state.username}
		      email={this.state.email}
		      addUser={this.addUser}
		      handleChange={this.handleChange}
		    />
		    <br/>
		    <UsersList users={this.state.users}/>
		  </div>
		)} />
		<Route exact path='/about' component={About}/>
	      </Switch>
	    </div>
	  </div>
	</div>
	)
    }

    getUsers(){
	axios.get(`${process.env.REACT_APP_USERS_SERVICE_URL}/users`)
	    .then((res) => { this.setState({ users: res.data.data.users }); })
	    .catch((err) => { console.log(err); });
    }

    addUser(event) {
	event.preventDefault();
	const data = {
	    username: this.state.username,
	    email: this.state.email
	};
	axios.post(`${process.env.REACT_APP_USERS_SERVICE_URL}/users`, data)
	    .then((res) => {
		this.getUsers();
		this.setState({ username: '', email: ''});
	    })
	    .catch((err) => { console.log(err); });
    }

    handleChange(event) {
	const obj = {};
	obj[event.target.name] = event.target.value;
	this.setState(obj);
    }

};

export default App;
