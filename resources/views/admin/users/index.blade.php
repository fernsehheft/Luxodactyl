@extends('layouts.admin')

@section('title')
    List Users
@endsection

@section('content-header')
    <h1>Users<small>All registered users on the system.</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Users</li>
    </ol>
@endsection

@section('content')
<div class="row">
    <div class="col-xs-12">
        <div style="margin-bottom: 16px; text-align: right;">
            <a href="{{ route('admin.users.new') }}" class="btn btn-primary">
                <i class="fa fa-plus"></i> Create New
            </a>
        </div>
        <div id="admin-users-app"></div>
    </div>
</div>
@endsection
